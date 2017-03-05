# Cards class
`Cards` 类描述了一个语言环境下的卡片集合。
## 函数
名称|返回|说明
----|----|----
constructor(lang[, constantFilepath])|构造|以给定参数为语言，创建一个新集合。
getCardById(id)|Card|查询指定ID的卡片。
getCardByIdASync(id, callback(card))|0|查询指定ID的卡片。`*`
getAttributeName(card)|String|获得卡片在本语言下的的属性名。
getRaceName(card)|String|获得卡片在本语言下的的种族名。
[id]|Card|查询指定ID的卡片。会触发**同步**查询。

`*` 使用 `sqlite3` 的异步方法可能更稳定。

## 静态函数
名称|参数|说明
----|----|----
Cards[lang]|'zh-CN'|获取以此参数初始化的 Cards 对象。

# Card class
`Card` 描述了一张卡。

**请注意，`Card` 类的多数函数由 `Constant.lua` 中的内容动态生成。**

之所以写在文档中，是因为我们近似认为 `Costant.lua` 是近似不变的。

**不同配置的生成的字段会混杂在一起。**

不由动态生成得到者在下文中会用 `*` 注明。

## 基本字段
名称|说明
---|---
id|卡片 ID
ot|O/T 字段
alias|别名
setcode|字段
type|类别
category|分类
name|卡名
desc|卡片描述
level|等级，怪兽卡片才具有
pendulumScale|灵摆刻度，其他怪兽为 `-1`
race|种族，怪兽卡片才具有
attribute|属性，怪兽卡片才具有
atk|攻击力，怪兽卡片才具有
def|防御力，怪兽卡片才具有
## 生成字段
名称|说明
---|---
`*` isAlias| 此卡是否另一张卡的别名
`*` isOcg| 此卡是否在 `OCG` 卡池中
`*` isTcg| 此卡是否在 `TCG` 卡池中
`*` isEx|此卡游戏开始时是否在额外卡组中
isTypeMonster| 是否是怪兽
isTypeSpell|是否是魔法
isTypeTrap|是否是陷阱
isTypeNormal|是否是通常（怪兽）
isTypeEffect|是否是效果（怪兽）
isTypeFusion|是否是融合（怪兽）
isTypeRitual|是否是仪式（怪兽）
isTypeTrapMonster|是否是陷阱怪兽 `**`
isTypeSpirit|是否是灵魂（怪兽）
isTypeUnion|是否是联合（怪兽）
isTypeDual|是否是二重（怪兽）
isTypeTuner|是否是调整（怪兽）
isTypeSynchro|是否是同调（怪兽）
isTypeToken|是否是衍生物
isTypeQuickplay|是否是速攻（魔法）
isTypeContinuous|是否是永续（魔法/陷阱）
isTypeEquip|是否是装备（魔法）
isTypeField|是否是场地（魔法）
isTypeCounter|是否是反击（陷阱）
isTypeFlip|是否是反转（怪兽）
isTypeToon|是否是卡通（怪兽）
isTypeXyz|是否是XYZ（怪兽）
isTypePendulum|是否是灵摆（怪兽）
isTypeSpsummon|是否是特殊召唤（怪兽）
isAttributeEarth|是否是地属性
isAttributeWater|是否是水属性
isAttributeFire|是否属火属性
isAttributeWind|是否是风属性
isAttributeLight|是否是光属性
isAttributeDark|是否是暗属性
isAttributeDevine|是否是神属性
isRaceWarrior|是否是战士族
isRaceSpellcaster|是否是魔法使族
isRaceFairy|是否是天使族
isRaceFend|是否是恶魔族
isRaceZombie|是否是不死族
isRaceMachine|是否是机械族
isRaceAqua|是否是水族
isRacePyro|是否是炎族
isRaceRock|是否是岩石族
isRaceWindbeast|是否是鸟兽族
isRacePlant|是否是植物族
isRaceInsect|是否是昆虫族
isRaceThunder|是否是雷族
isRaceDragon|是否是龙族
isRaceBeast|是否是兽族
isRaceBeastWarrior|是否是兽战士族
isRaceDinosaur|是否是恐龙族
isRaceFish|是否是鱼族
isRaceSeaeprent|是否是海龙族
isRaceReptile|是否是爬虫类族
isRacePsychro|是否是念动力族
isRaceDevine|是否是幻神兽族
isRaceCreatorgod|是否是创造神族
isRaceWyrm|是否是幻龙族
isRaceCybers|是否是电子界族
`**` 对于从数据库读出来的卡说，此项永远为 `false`。