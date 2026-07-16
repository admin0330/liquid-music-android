package io.github.admin0330.liquidmusic.feature.home

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Article
import androidx.compose.material.icons.rounded.Code
import androidx.compose.material.icons.rounded.LibraryMusic
import androidx.compose.material.icons.rounded.OpenInNew
import androidx.compose.material.icons.rounded.Public
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import io.github.admin0330.liquidmusic.core.designsystem.components.liquidClickable
import io.github.admin0330.liquidmusic.core.designsystem.glass.LiquidGlassHost
import io.github.admin0330.liquidmusic.core.designsystem.glass.LiquidGlassSurface
import io.github.admin0330.liquidmusic.core.designsystem.tokens.LiquidSpacing

@Composable
fun HomeScreen(
    bottomPadding: Dp,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val openExternal = remember(context) {
        { url: String ->
            val uri = url.toUri()
            if (uri.scheme.equals("https", ignoreCase = true)) {
                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
            }
        }
    }

    LiquidGlassHost(
        modifier = modifier.fillMaxSize(),
        background = { source -> PersonalHomeBackdrop(source) },
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().statusBarsPadding(),
            contentPadding = PaddingValues(
                start = LiquidSpacing.screen,
                top = LiquidSpacing.xs,
                end = LiquidSpacing.screen,
                bottom = bottomPadding + LiquidSpacing.md,
            ),
            verticalArrangement = Arrangement.spacedBy(LiquidSpacing.md),
        ) {
            item(key = "header") {
                PersonalHomeHeader(onOpenSettings = onOpenSettings)
            }
            item(key = "profile") {
                ProfileHero(
                    onOpenBlog = { openExternal(BLOG_URL) },
                    onOpenGitHub = { openExternal(GITHUB_PROFILE_URL) },
                )
            }
            item(key = "spaces-title") {
                SectionTitle("我的空间", "Native shortcuts")
            }
            item(key = "spaces") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(LiquidSpacing.sibling),
                ) {
                    PersonalLinkTile(
                        title = "Ym1r World",
                        subtitle = "文章与动态",
                        icon = Icons.Rounded.Public,
                        onClick = { openExternal(BLOG_URL) },
                        modifier = Modifier.weight(1f),
                    )
                    PersonalLinkTile(
                        title = "GitHub",
                        subtitle = "开源项目",
                        icon = Icons.Rounded.Code,
                        onClick = { openExternal(GITHUB_PROFILE_URL) },
                        modifier = Modifier.weight(1f),
                    )
                }
            }
            item(key = "project-title") {
                SectionTitle("正在做", "Featured project")
            }
            item(key = "project") {
                FeaturedProjectCard(onClick = { openExternal(LIQUID_MUSIC_REPOSITORY_URL) })
            }
            item(key = "note-title") {
                SectionTitle("最近动态", "Latest note")
            }
            item(key = "note") {
                LatestNoteCard(onClick = { openExternal(NOTES_URL) })
            }
        }
    }
}

@Composable
private fun PersonalHomeBackdrop(modifier: Modifier) {
    val accent = MaterialTheme.colorScheme.primary
    Box(
        modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.surface.copy(alpha = 0.94f),
                        MaterialTheme.colorScheme.background,
                    ),
                ),
            ),
    ) {
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .offset(x = 96.dp, y = (-76).dp)
                .size(300.dp)
                .clip(CircleShape)
                .background(Brush.radialGradient(listOf(accent.copy(alpha = 0.26f), Color.Transparent))),
        )
        Box(
            Modifier
                .align(Alignment.CenterStart)
                .offset(x = (-132).dp, y = 84.dp)
                .size(280.dp)
                .clip(CircleShape)
                .background(Brush.radialGradient(listOf(Color(0xFF8E6BFF).copy(alpha = 0.16f), Color.Transparent))),
        )
    }
}

@Composable
private fun PersonalHomeHeader(onOpenSettings: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().height(56.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column {
            Text(
                text = "主页",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = "Ym1r World",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.weight(1f))
        LiquidGlassSurface(
            modifier = Modifier
                .size(48.dp)
                .semantics {
                    role = Role.Button
                    contentDescription = "设置"
                }
                .liquidClickable(onClick = onOpenSettings),
            cornerRadius = 24.dp,
            blurRadius = 24.dp,
            opacity = 0.34f,
            elevation = 3.dp,
        ) {
            Icon(
                imageVector = Icons.Rounded.Settings,
                contentDescription = null,
                modifier = Modifier.align(Alignment.Center).size(23.dp),
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.84f),
            )
        }
    }
}

@Composable
private fun ProfileHero(
    onOpenBlog: () -> Unit,
    onOpenGitHub: () -> Unit,
) {
    LiquidGlassSurface(
        modifier = Modifier.fillMaxWidth(),
        blurRadius = 34.dp,
        opacity = 0.34f,
        cornerRadius = 30.dp,
        elevation = 5.dp,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(LiquidSpacing.lg),
            verticalArrangement = Arrangement.spacedBy(LiquidSpacing.md),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                listOf(
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.94f),
                                    Color(0xFF8E6BFF).copy(alpha = 0.92f),
                                ),
                            ),
                        )
                        .border(1.dp, Color.White.copy(alpha = 0.34f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "Y",
                        style = MaterialTheme.typography.headlineLarge,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
                Column(
                    modifier = Modifier.padding(start = LiquidSpacing.md),
                    verticalArrangement = Arrangement.spacedBy(LiquidSpacing.xxs),
                ) {
                    Text(
                        text = "Ym1r",
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(7.dp).clip(CircleShape).background(Color(0xFF36D67E)))
                        Text(
                            text = "Hi, delay no more!",
                            modifier = Modifier.padding(start = LiquidSpacing.xs),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            Text(
                text = "记录开源项目、Android 与正在发生的想法。",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.80f),
            )

            Row(horizontalArrangement = Arrangement.spacedBy(LiquidSpacing.xs)) {
                ProfileTag("ANDROID")
                ProfileTag("OPEN SOURCE")
                ProfileTag("MUSIC")
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(LiquidSpacing.sibling),
            ) {
                ProfileAction(
                    label = "打开博客",
                    icon = Icons.Rounded.Public,
                    primary = true,
                    onClick = onOpenBlog,
                    modifier = Modifier.weight(1f),
                )
                ProfileAction(
                    label = "GitHub",
                    icon = Icons.Rounded.Code,
                    primary = false,
                    onClick = onOpenGitHub,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun ProfileTag(label: String) {
    Box(
        modifier = Modifier
            .height(28.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.075f))
            .padding(horizontal = LiquidSpacing.sm),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun ProfileAction(
    label: String,
    icon: ImageVector,
    primary: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val background = if (primary) {
        MaterialTheme.colorScheme.primary.copy(alpha = 0.88f)
    } else {
        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.09f)
    }
    val foreground = if (primary) Color.White else MaterialTheme.colorScheme.onSurface
    Row(
        modifier = modifier
            .height(48.dp)
            .clip(CircleShape)
            .background(background)
            .semantics {
                role = Role.Button
                contentDescription = label
            }
            .liquidClickable(onClick = onClick)
            .padding(horizontal = LiquidSpacing.md),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp), tint = foreground)
        Text(
            text = label,
            modifier = Modifier.padding(start = LiquidSpacing.xs),
            style = MaterialTheme.typography.labelLarge,
            color = foreground,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun SectionTitle(title: String, eyebrow: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(top = LiquidSpacing.xs),
        verticalAlignment = Alignment.Bottom,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.weight(1f))
        Text(
            text = eyebrow.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.68f),
        )
    }
}

@Composable
private fun PersonalLinkTile(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LiquidGlassSurface(
        modifier = modifier
            .height(112.dp)
            .semantics {
                role = Role.Button
                contentDescription = "$title，$subtitle"
            }
            .liquidClickable(onClick = onClick),
        blurRadius = 28.dp,
        opacity = 0.30f,
        cornerRadius = 24.dp,
        elevation = 3.dp,
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(LiquidSpacing.md),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(25.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                )
            }
        }
    }
}

@Composable
private fun FeaturedProjectCard(onClick: () -> Unit) {
    LiquidGlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .semantics {
                role = Role.Button
                contentDescription = "打开 Liquid Music Android GitHub 仓库"
            }
            .liquidClickable(onClick = onClick),
        blurRadius = 32.dp,
        opacity = 0.34f,
        cornerRadius = 26.dp,
        elevation = 4.dp,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(LiquidSpacing.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.16f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Rounded.LibraryMusic,
                    contentDescription = null,
                    modifier = Modifier.size(29.dp),
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
            Column(
                modifier = Modifier.weight(1f).padding(horizontal = LiquidSpacing.md),
                verticalArrangement = Arrangement.spacedBy(LiquidSpacing.xxs),
            ) {
                Text(
                    text = "Liquid Music Android",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = "原生、本地、无损音乐播放器",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                )
            }
            Icon(
                imageVector = Icons.Rounded.OpenInNew,
                contentDescription = null,
                modifier = Modifier.size(21.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun LatestNoteCard(onClick: () -> Unit) {
    LiquidGlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .semantics {
                role = Role.Button
                contentDescription = "打开 Ym1r World 动态"
            }
            .liquidClickable(onClick = onClick),
        blurRadius = 28.dp,
        opacity = 0.28f,
        cornerRadius = 24.dp,
        elevation = 3.dp,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(LiquidSpacing.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Rounded.Article,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
            Column(
                modifier = Modifier.weight(1f).padding(horizontal = LiquidSpacing.md),
                verticalArrangement = Arrangement.spacedBy(LiquidSpacing.xxs),
            ) {
                Text(
                    text = "Hello",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = "欢迎来到 Ym1r World。",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                )
            }
            Icon(
                imageVector = Icons.Rounded.OpenInNew,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

private const val BLOG_URL = "https://ym3861.cn/blog"
private const val NOTES_URL = "https://ym3861.cn/blog/timeline?type=note"
private const val GITHUB_PROFILE_URL = "https://github.com/admin0330"
private const val LIQUID_MUSIC_REPOSITORY_URL = "https://github.com/admin0330/liquid-music-android"
