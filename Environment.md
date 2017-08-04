# Environment class
`Environment` 描述了一个语言环境。

## 静态函数
名称|参数|说明
---|---|---
new|locale|创建一个具有`locale`的`Environment`
[]|locale|若你曾创建过具有此`locale`的`Environment`，返回之。

## 字段
名称|说明
----|----
locale|环境语言
attributes|此环境下的属性数组
types|此环境下的类别数组
sets|此环境下的系列数组
cards|缓存中的卡片。

`Environment` 载入卡片使用了缓存。没有使用过的卡片，不会出现在 `cards` 中。

## 函数
名称|参数|说明
----|----|----
[]|id|检索此环境下具有id的卡片。没有的话，会返回 `undefined`
loadAllCards|-|载入所有卡片到 `cards`
