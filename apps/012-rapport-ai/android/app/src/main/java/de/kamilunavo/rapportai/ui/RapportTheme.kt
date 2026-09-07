package de.kamilunavo.rapportai.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Navy = Color(0xFF07111F)
val Surface = Color(0xFF101D2E)
val Raised = Color(0xFF192A3D)
val Cyan = Color(0xFF28D7E5)
val Orange = Color(0xFFFF8A32)
val Muted = Color(0xFF9BACBE)

private val Scheme = darkColorScheme(
    primary = Orange,
    onPrimary = Navy,
    secondary = Cyan,
    onSecondary = Navy,
    background = Navy,
    onBackground = Color.White,
    surface = Surface,
    onSurface = Color.White,
    surfaceVariant = Raised,
    onSurfaceVariant = Muted,
    outline = Color(0xFF35475B),
    error = Color(0xFFFF6B6B)
)

@Composable
fun RapportTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = Scheme, typography = MaterialTheme.typography, content = content)
}
