# Scavengers Reign — Vesta Quiet Walk

为 M1/16GB Mac 制作的轻量 Godot 4 私人同人体验。重点不是任务、胜负或生存数值，而是慢慢行走、观看 Vesta 群落自行运转，并听环境的层次变化。

这是非商业 fan study。项目不包含剧集截图、原声或提取素材；程序化3D场景用接近二维动画的哑光色块、雾化层次与低面数剪影来研究《Scavengers Reign》的生态氛围。

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

## Reference-based 3D models

The existing `assets/vesta_hihat_cluster.png` and `assets/vesta_foreground_flora.png` are translated into two reusable Godot scenes:

- `assets/models/vesta_hihat_cluster_3d.tscn`: five umbrella trees with roots, canopy ribs, scalloped crowns, perforated hanging membranes, and trunk collisions.
- `assets/models/vesta_foreground_flora_3d.tscn`: pleated fan leaves with raised veins, perforated coral fronds, dark finger plants, pearl growths, and hollow spore cups.

Four tree groves and six foreground beds are placed in the playable basin. Leaves and hanging membranes sway from anchored pivots. Meshes are baked into the scenes and shared between instances; static pieces are batched by material. The source drawings are references only, never billboards.

Rebuild the models after editing `scripts/plant_model_factory.gd` or `scripts/botanical_mesh.gd`:

```bash
/path/to/godot --headless --path . --script res://tools/build_plant_models.gd
```

Run `tools/preview_models.gd` with a graphical Godot session to save `assets/models/in_game_preview.png`.

The foreground flora now uses curved, rounded tube meshes with spreading roots, broader overlapping fan surfaces, smooth elliptical membrane openings, and a restrained ink-outline material. Pigment shading preserves the deep plum / sage / coral palette instead of washing it out under the basin light. These are stylized 3D interpretations; the original illustration's hand-drawn marks are not reproduced exactly.

## Basin ground art

The ground uses a continuous world-space tidal material: irregular shallow-water shapes, dark damp margins, muted clay and sediment bands, with slow painted sky-color movement across water. It is stylized water shading, not real scene reflections. `scripts/basin_terrain.gd` adds 680 batched gravel pieces, 30 low basalt rocks with convex collision, 18 silt banks, and distant basin shelves. The level's walkable base remains flat; low relief supplies the visual terrain detail. The rectangular puddles and repeated ground pattern have been removed.

`tools/preview_models.gd` now saves the ground-focused in-game view to `assets/models/ground_preview.png`.

## Blender creature pass

Pigoid and Sterq now use the rigged Blender models in `assets/creatures/models/` instead of primitive shapes. Editable `.blend` files, baked skin textures, build scripts and known visual limitations are documented in `assets/creatures/README.md`. Idle, walk and feeding/alert clips are connected to the existing ecology behavior.
