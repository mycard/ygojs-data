
# Sets Class
`Sets` 类描述了一个语言环境下由 `Strings` 描述的字段集合。
## 字段
名称|类型|说明
----|----|----
sets|[Set]|该环境下的所有字段
## 函数
名称|返回|说明
----|----|----
constructor(lang)|构造|以给定参数为语言，创建一个新集合。
## 静态字段
名称|返回|说明
----|----|---
Sets[lang]|Sets|获取以此参数初始化的 Sets 对象。

# Set Class
`Set` 类描述了一个游戏王字段。
## 字段
字段|类型|说明
----|:----:|----
number|int|其 ID 值。
name|string|`strings` 中记载的名称。
parent|Sets|属于哪个 `Sets` 类
ids|[id]|包含的卡的 ID。**可能为空。**
## 函数
函数|返回|说明
----|----|----
includes(`Card` / id)|bool|此字段是否包含该卡。若ids为空则会触发**同步**查询。
includesAsync(`Card` / id, callback(bool))|0|此字段是否包含该卡。若ids为空则会触发查询。