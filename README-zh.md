[English](README.md) | [Chinese / 中文](README-zh.md)

# 苔汐星 · Mossara

**苔汐星 · Mossara** 是这颗星球的名字。“苔”对应潮湿、缓慢生长的生态，“汐”带出浅水盆地与周期变化。

为 M1/16GB Mac 制作的轻量 Godot 4 探索体验。重点不是任务、胜负或生存数值，而是慢慢行走、观看生态群落自行运转，并听环境的层次变化。

这是受《Scavengers Reign》启发的非商业同人研究。项目不包含剧集截图、原声或提取素材；程序化 3D 场景用接近二维动画的哑光色块、雾化层次与低面数剪影来研究剧集的生态氛围。现有构建和素材路径仍沿用早期名称 **Vesta Quiet Walk**。

## 目前体验


- 没有主线、开门谜题、倒计时或通关目标。
- 正常移动速度与克制的66°视角；按住 `Shift` 才会慢走观察。
- 雨后浅水盆地与完整3D生态群：有分叉骨架和双层伞盖的 Hi-hat trees、立体膜状植物、扇叶群落、孢子杯与远景 Rain Skimmers。
- Spore Trees、Pigoids 与 Sterq Serpents 会进食、追踪、逃避和缓慢游荡。
- 程序化生成风、低频、水滴与稀疏生物鸣叫，不需要外部音频文件。
- 接近生物会自动留下观察记录；`Tab` 可随时查看。
- `Q` 留下一小段气味痕迹，`E` 发出柔和地面脉冲；两者完全可选。
- Compatibility 渲染器和低面数模型，适合 M1/16GB。

更具体的美术与声音原则见 [ART_DIRECTION.md](ART_DIRECTION.md)。

## 运行

双击 `launch_godot.command`；或者在 Godot 4 中 Import 本目录的 `project.godot` 后运行。

操作：

- `WASD`：移动
- `Shift`：按住慢走
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
4. 继续用定制网格和骨骼动画替换剩余的基础几何体。

## 基于参考图的 3D 模型

现有的 `assets/vesta_hihat_cluster.png` 和 `assets/vesta_foreground_flora.png` 被转化为两个可复用的 Godot 场景：

- `assets/models/vesta_hihat_cluster_3d.tscn`：五棵伞状树，包含根系、伞盖骨架、波瓣状树冠、带孔的悬垂膜片与树干碰撞体。
- `assets/models/vesta_foreground_flora_3d.tscn`：带凸起叶脉的褶皱扇叶、带孔珊瑚状叶片、深色指状植物、珍珠状生长物和中空孢子杯。

可游玩的盆地中放置了四组树林与六组前景植物。叶片和悬垂膜片围绕固定支点摆动。网格已烘焙进场景，并在实例之间共享；静态部分按材质批处理。原始绘图只作为参考，不作为面向镜头的平面贴图。

修改 `scripts/plant_model_factory.gd` 或 `scripts/botanical_mesh.gd` 后，可重新生成模型：

```bash
/path/to/godot --headless --path . --script res://tools/build_plant_models.gd
```

在带图形界面的 Godot 会话中运行 `tools/preview_models.gd`，可将预览保存到 `assets/models/in_game_preview.png`。

前景植物使用弯曲圆润的管状网格、向外伸展的根系、更宽且互相叠合的扇面、平滑的椭圆膜孔，以及克制的墨线描边材质。色素着色保留深梅紫、鼠尾草绿与珊瑚色，避免在盆地光照下褪色。这些模型是风格化的 3D 演绎，并不精确复刻原图的手绘笔触。

## 盆地地表美术

地表使用连续的世界空间潮汐材质：不规则的浅水形状、深色湿润边缘、低饱和的黏土与沉积带，以及水面上缓慢移动的天空色彩。这是风格化的水面着色，并非真实场景反射。`scripts/basin_terrain.gd` 添加了 680 个批处理碎石、30 块带凸形碰撞体的低矮玄武岩、18 处淤泥滩与远景盆地台地。可行走的基础地面仍然平坦，通过低起伏表现地形细节。矩形水洼与重复地表图案已移除。

`tools/preview_models.gd` 现在会将以地表为重点的游戏内视图保存到 `assets/models/ground_preview.png`。

## Blender 生物模型

Pigoid 和 Sterq 现在使用 `assets/creatures/models/` 中的 Blender 绑定模型，替代原始几何体。可编辑的 `.blend` 文件、烘焙皮肤贴图、构建脚本与已知视觉限制记录在 [生物模型说明](assets/creatures/README.md) 中。待机、行走、进食或警戒动画已接入现有生态行为。
