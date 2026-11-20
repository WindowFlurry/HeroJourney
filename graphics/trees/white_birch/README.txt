白桦树与白桦林地素材（1x 像素图）

五种白桦树（已全部用于第一关，运行时随机分布）：
A 单株高白桦     32 x 56   white_birch_a_single.png
B 双株白桦       44 x 56   white_birch_b_twin.png
C 幼白桦         32 x 32   white_birch_c_young.png
D 宽冠白桦       48 x 56   white_birch_d_broad.png
E 金叶白桦       32 x 56   white_birch_e_gold.png

林地小景：
white_birch_stump.png   白桦树桩
white_birch_log.png     倒下的白桦
white_birch_flower.png  白花
white_birch_fern.png    蕨类
white_birch_sign.png    林地木牌

预览：
preview_white_birch.png   五种白桦树 4x 对比图
preview_birch_details.png 林地小景 4x 对比图

第一关的生成方式：
- game.gd 在运行时读取原有棕树位置；
- 保留约 22% 的棕树（本次 31 棵中保留 6 棵），其余替换为白桦；
- 五种白桦按权重随机，D/E 较稀有；
- 每个替换点附近会增加 0~1 棵白桦，并散布树桩/倒木/白花/蕨类；
- 在林地入口附近放置「白桦林地」木牌；
- 使用固定随机种子，重开地图时布局一致。

注意：森林是运行时生成的，所以直接在 Godot 编辑器里打开 game.tscn
仍然会显示旧棕树；运行游戏后才会看到白桦林。
