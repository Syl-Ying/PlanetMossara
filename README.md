# Scavengers Reign — Vesta Quiet Walk

为 M1/16GB Mac 制作的轻量 Godot 4 私人同人体验。重点不是任务、胜负或生存数值，而是慢慢行走、观看 Vesta 群落自行运转，并听环境的层次变化。

这是非商业 fan study。项目不包含剧集截图、原声或提取素材；程序化3D场景用接近二维动画的哑光色块、雾化层次与低面数剪影来研究《Scavengers Reign》的生态氛围。

## 目前体验

- 没有主线、开门谜题、倒计时或通关目标。
- 较慢的第一人称漫游速度与克制的66°视角。
- 雨后浅水盆地、Hi-hat trees、膜状植物、指状低矮群落与远景 Rain Skimmers。
- Spore Trees、Pigoids 与 Sterq Serpents 会进食、追踪、逃避和缓慢游荡。
- 程序化生成风、低频、水滴与稀疏生物鸣叫，不需要外部音频文件。
- 接近生物会自动留下观察记录；`Tab` 可随时查看。
- `Q` 留下一小段气味痕迹，`E` 发出柔和地面脉冲；两者完全可选。
- Compatibility 渲染器和低面数模型，适合 M1/16GB。

更具体的美术与声音原则见 [ART_DIRECTION.md](ART_DIRECTION.md)。

## 运行

双击 `launch_godot.command`；或者在 Godot 4 中 Import 本目录的 `project.godot` 后运行。

操作：

- `WASD`：缓慢行走
- 鼠标：观察
- `Q`：气味痕迹（可选）
- `E`：柔和脉冲（可选）
- `Tab`：观察记录
- `Esc`：释放鼠标

## 自动验证

```bash
/path/to/godot --headless --path . --script res://tests/smoke_test.gd
```

## 下一步

1. 加入昼夜与降雨密度的极慢变化。
2. 为不同生物增加距离分层的环境声，而不是背景音乐。
3. 加入“只发生一次、也可能被错过”的无任务生态事件。
4. 用手绘贴图与更精细的低模轮廓继续逼近二维动画质感。
