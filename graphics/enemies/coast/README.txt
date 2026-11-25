赤烬海岸敌人

来源：front_view_chibi/
选用的 8 张参考原图已整理到 reference/。
每个 sheet 为 3 列 × 2 行：
- 列：待机 / 移动 / 攻击
- 行：朝左 / 朝右
攻击帧带简单的武器或元素特效；游戏脚本按列切换。

小怪：
- ash_feather（48px）      灰烬鸟，远程灰烬弹
- dragonfire_digger（56px）龙火矿工，近战
- slag_skink（48px）       熔渣蜥，快速近战
- ferry_strangler（56px）  海藻鬼，慢速高血量近战
- gamehound（48px）        猎犬，快速近战

精英：
- menhir_golem（64px）         石魔像，震地范围攻击
- lava_span_basilisk（64px）   熔岩蛇蜥，三连火焰弹
- cinder_falcon（64px）        烬隼，三连火焰羽

Boss：
- ska_sheet.png（128px）
  以 lava_span_basilisk 为基底重绘：更凶的眉骨/红眼/尖牙、
  更大的头冠和背刺、口部余烬裂纹，并加入火焰吐息攻击帧。
  两阶段逻辑在 scenes/coast/ska.gd。

预览图：preview_coast_enemies.png
生成脚本：docs/coast_enemy_sheets.py
