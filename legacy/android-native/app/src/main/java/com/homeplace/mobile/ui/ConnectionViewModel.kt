package com.homeplace.mobile.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.homeplace.mobile.network.AddressResult
import com.homeplace.mobile.network.LinkInfoClient
import com.homeplace.mobile.network.ServerAddressNormalizer
import com.homeplace.mobile.network.ServerInfoResult
import com.homeplace.mobile.network.ServerInfoService
import com.homeplace.mobile.protocol.ServerInfo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class ConnectionStage { WELCOME, ADDRESS, VALIDATING, PREVIEW }

data class ConnectionState(
    val stage: ConnectionStage = ConnectionStage.WELCOME,
    val address: String = "",
    val normalizedUrl: String? = null,
    val isSecure: Boolean = false,
    val serverInfo: ServerInfo? = null,
    val error: String? = null,
)

class ConnectionViewModel(
    private val service: ServerInfoService = LinkInfoClient(),
) : ViewModel() {
    private val mutableState = MutableStateFlow(ConnectionState())
    val state: StateFlow<ConnectionState> = mutableState.asStateFlow()

    fun continueFromWelcome() = mutableState.update { it.copy(stage = ConnectionStage.ADDRESS) }

    fun setAddress(value: String) = mutableState.update { it.copy(address = value, error = null) }

    fun editAddress() = mutableState.update {
        it.copy(stage = ConnectionStage.ADDRESS, serverInfo = null, normalizedUrl = null, error = null)
    }

    fun validate() {
        val result = ServerAddressNormalizer.normalize(mutableState.value.address)
        if (result is AddressResult.Invalid) {
            mutableState.update { it.copy(stage = ConnectionStage.ADDRESS, error = result.message) }
            return
        }
        result as AddressResult.Valid
        mutableState.update {
            it.copy(
                stage = ConnectionStage.VALIDATING,
                normalizedUrl = result.address.url.toString().trimEnd('/'),
                isSecure = result.address.isSecure,
                error = null,
            )
        }
        viewModelScope.launch {
            when (val response = service.fetch(result.address)) {
                is ServerInfoResult.Success -> mutableState.update {
                    it.copy(stage = ConnectionStage.PREVIEW, serverInfo = response.info)
                }
                is ServerInfoResult.Failure -> mutableState.update {
                    it.copy(stage = ConnectionStage.ADDRESS, error = response.message)
                }
            }
        }
    }
}
