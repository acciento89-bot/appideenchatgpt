package de.kamilunavo.rapportai.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.Shapes
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Navy = Color(0xFF07111F)
val Surface = Color(0xFFFFFDF7)
val Raised = Color(0xFFEDE5D6)
val Cyan = Color(0xFF2C6368)
val Orange = Color(0xFFA84711)
val Muted = Color(0xFF5B625F)

private val Scheme = lightColorScheme(
    primary = Orange,
    primaryContainer = Color(0xFFF4DCCA),
    onPrimaryContainer = Navy,
    onPrimary = Color.White,
    secondary = Cyan,
    secondaryContainer = Color(0xFFDCEBE7),
    onSecondaryContainer = Color(0xFF153F42),
    onSecondary = Color.White,
    background = Color(0xFFF4EFE3),
    onBackground = Navy,
    surface = Surface,
    surfaceContainerLowest = Surface,
    surfaceContainerLow = Surface,
    surfaceContainer = Surface,
    surfaceContainerHigh = Surface,
    surfaceContainerHighest = Raised,
    surfaceTint = Color.Transparent,
    onSurface = Navy,
    surfaceVariant = Raised,
    onSurfaceVariant = Muted,
    outline = Color(0xFFCEC6B7),
    onError = Color.White,
    errorContainer = Color(0xFFFCE5DF),
    onErrorContainer = Color(0xFF6F1D19),
    error = Color(0xFFB92E27)
)

@Composable
fun RapportTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = Scheme, typography = brandedTypography(), shapes = Shapes(small = RoundedCornerShape(4.dp), medium = RoundedCornerShape(4.dp), large = RoundedCornerShape(6.dp), extraLarge = RoundedCornerShape(8.dp)), content = content)
}
