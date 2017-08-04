# Deck Class
`Deck` 描述了一个卡组。

## 字段
字段|类型|说明
----|:----:|----
main|[`Card` or id]|主卡组
side|[`Card` or id]|备牌
ex|[`Card` or id]|额外
classifiedMain|{[`Card` or id] => int}|分类后的主卡组，可能为空
classifiedSide|{[`Card` or id] => int}|分类后的备牌，可能为空
classifiedEx|{[`Card` or id] => int}|分类后的额外，可能为空
form|string|

## form 取值
值|说明
----|----
id|`main` `side` `ex` 中的值为卡片 id
card|`main` `side` `ex` 中的值为 `Card` 对象

## 函数
字段|返回|说明
----|:----:|----
classify|this|将卡片分类，在那之前 `classifiedX` 为空。
separateExFromMain|this|将主卡组中的额外怪兽放置到额外中。
tranFromToCards|this|将 `form` 变更为 `card`。
transformToID|this|将 `form` 变更为 `id`

## 静态函数
字段|返回|说明
----|:----:|----
fromString|`Deck`|从字符串中读取卡组
fromFileSync|`Deck`|从文件中读取卡组