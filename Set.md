# Set Class
`Set` 类描述了一个游戏王字段。
## 字段
字段|类型|说明
----|:----:|----
number|int|其 ID 值。
name|string|`strings` 中记载的名称。 `**`
originName|string|
ids|[id]|包含的卡的 ID。
`**`
+ 对于 `zh-CN` 而言，其值为 `name\toriginName`
+ 对于 `ja-JP` 而言，其值为 `originName`
+ 对于 `en-US` 而言，不存在任何能查询到的 `Set` 值。

## 函数
函数|返回|说明
----|----|----
includes(`Card` / id)|bool|此字段是否包含该卡。若ids为空则会触发**同步**查询。
separateOriginNameFromName|true|从 `name` 中分离出 `originName`