# Replay Class
描述了一个回放文件。
## 静态方法
函数名|返回类型|说明
----|----|----
fromFile(filePath)|Replay|从文件中读取录像
fromBuffer(buffer)|Replay|从Buffer对象中读取录像
## 字段
字段|类型|说明
----|:----:|----
header|`replayHeader`|
hostName|string|主机用户名
clientName|string|客户机用户名
startLp|int|游戏开始时双方LP
startHand|int|游戏开始时双方手牌数
drawCount|int|双方每回合抓的牌数
opt|int|游戏环境（O/T）
hostDeck|int|主机使用的卡组
clientDeck|int|客户机使用的卡组
decks|[`Deck`]|所有本录像中包含的卡组

## `TAG` 字段
字段|类型|说明
----|:----:|----
isTag|bool|转发 header.isTag
tagHostName|string|TAG 主机用户名
tagClientName|string|TAG 客户机用户名
tagHostDeck|int|TAG 主机使用的卡组
tagClientDeck|int|TAG客户机使用的卡组
这些字段均仅当回放为一场 `TAG` 决斗时才生效。

# replayHeader Class
`replayHeader` 类抽象了录像的文件头。是录像的一部分。
## 字段
字段|类型|说明
----|----|----
dataSize|int|
isTag|bool|指出此回放是否一场 TAG 决斗。
isCompressed|bool|指出此回放内容是否经过LZMA压缩。

## Native 字段
字段|类型
----|----
id|int
version|int
flag|int
seed|int
dataSizeRaw|[int 4]
hash|int
props|[int 8]