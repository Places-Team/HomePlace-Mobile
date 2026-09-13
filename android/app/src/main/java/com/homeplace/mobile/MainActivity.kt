package com.homeplace.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.homeplace.mobile.ui.ConnectionStage
import com.homeplace.mobile.ui.ConnectionViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { HomePlaceApp() }
    }
}

@Composable
private fun HomePlaceApp(viewModel: ConnectionViewModel = viewModel()) {
    val state by viewModel.state.collectAsState()
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    MaterialTheme(colorScheme = if (dark) darkColorScheme() else lightColorScheme()) {
        Surface(modifier = Modifier.fillMaxSize()) {
            Box(modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp), contentAlignment = Alignment.Center) {
                Column(
                    modifier = Modifier.widthIn(max = 520.dp).verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    when (state.stage) {
                        ConnectionStage.WELCOME -> Welcome(viewModel::continueFromWelcome)
                        ConnectionStage.ADDRESS,
                        ConnectionStage.VALIDATING,
                        -> AddressEntry(
                            value = state.address,
                            validating = state.stage == ConnectionStage.VALIDATING,
                            error = state.error,
                            onChange = viewModel::setAddress,
                            onConnect = viewModel::validate,
                        )
                        ConnectionStage.PREVIEW -> ServerPreview(state, viewModel::editAddress)
                    }
                }
            }
        }
    }
}

@Composable
private fun Welcome(onContinue: () -> Unit) {
    Text("⌂", style = MaterialTheme.typography.displayLarge, color = MaterialTheme.colorScheme.primary)
    Text(stringResource(R.string.app_name), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
    Text(stringResource(R.string.welcome_title), style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
    Text(stringResource(R.string.welcome_body), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
    Spacer(Modifier.height(8.dp))
    Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.get_started)) }
}

@Composable
private fun AddressEntry(
    value: String,
    validating: Boolean,
    error: String?,
    onChange: (String) -> Unit,
    onConnect: () -> Unit,
) {
    Text(stringResource(R.string.connect_title), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    Text(stringResource(R.string.connect_body), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        enabled = !validating,
        label = { Text(stringResource(R.string.server_address)) },
        placeholder = { Text(stringResource(R.string.server_hint)) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
        singleLine = true,
        isError = error != null,
        supportingText = error?.let { message -> { Text(message) } },
        modifier = Modifier.fillMaxWidth(),
    )
    Button(onClick = onConnect, enabled = value.isNotBlank() && !validating, modifier = Modifier.fillMaxWidth()) {
        if (validating) {
            CircularProgressIndicator(modifier = Modifier.height(20.dp), strokeWidth = 2.dp)
        } else {
            Text(stringResource(R.string.continue_action))
        }
    }
    if (validating) Text(
        stringResource(R.string.checking_server),
        modifier = Modifier.fillMaxWidth(),
        textAlign = TextAlign.Center,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun ServerPreview(state: com.homeplace.mobile.ui.ConnectionState, onEdit: () -> Unit) {
    val info = state.serverInfo ?: return
    Text(stringResource(R.string.server_ready), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
    Text(info.serverName, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            DetailRow(stringResource(R.string.server_url), state.normalizedUrl.orEmpty())
            DetailRow(stringResource(R.string.server_id), info.serverId)
            DetailRow(
                stringResource(R.string.security),
                stringResource(if (state.isSecure) R.string.connection_secure else R.string.connection_local_http),
            )
            DetailRow(stringResource(R.string.protocol), "${info.protocolMin}–${info.protocolMax}")
        }
    }
    Text(stringResource(R.string.pairing_waits), color = MaterialTheme.colorScheme.onSurfaceVariant)
    OutlinedButton(onClick = onEdit, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.use_another_address)) }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.Medium, modifier = Modifier.padding(start = 16.dp))
    }
}
