declare class Card {
    id: number
    ot: number
    alias?: number
    setcode: number
    declare class: number
    category: number
    name: string
    desc: string
    originLevel?: number
    level?: number
    pendulumScale: number
    linkMarkers: Array<boolean> | null
    linkNumber: number | null
    race?: number
    atribute?: number
    atk?: number
    def?: number

    static deckSortLevel(p1: Card, p2: Card): number
    static numText(num: number): string

    attributeText(): string
    raceText(): string
    typeText(): string
    atkText(): string
    defText(): string

    isAlias: boolean
    isOcg: boolean
    isTcg: boolean
    isEx: boolean

    isTypeMonster: boolean
    isTypeSpell: boolean
    isTypeTrap: boolean
    isTypeNormal: boolean
    isTypeEffect: boolean
    isTypeFusion: boolean
    isTypeRitual: boolean
    isTypeTrapMonster: boolean
    isTypeSpirit: boolean
    isTypeUnion: boolean
    isTypeDual: boolean
    isTypeTuner: boolean
    isTypeSynchro: boolean
    isTypeToken: boolean
    isTypeQuickplay: boolean
    isTypeContinuous: boolean
    isTypeEquip: boolean
    isTypeField: boolean
    isTypeCounter: boolean
    isTypeFlip: boolean
    isTypeToon: boolean
    isTypeXyz: boolean
    isTypePendulum: boolean
    isTypeSpsummon: boolean
    isTypeLink: boolean
    isAttributeEarth: boolean
    isAttributeWater: boolean
    isAttributeFire: boolean
    isAttributeWind: boolean
    isAttributeLight: boolean
    isAttributeDark: boolean
    isAttributeDevine: boolean
    isRaceWarrior: boolean
    isRaceSpellcaster: boolean
    isRaceFairy: boolean
    isRaceFend: boolean
    isRaceZombie: boolean
    isRaceMachine: boolean
    isRaceAqua: boolean
    isRacePyro: boolean
    isRaceRock: boolean
    isRaceWindbeast: boolean
    isRacePlant: boolean
    isRaceInsect: boolean
    isRaceThunder: boolean
    isRaceDragon: boolean
    isRaceBeast: boolean
    isRaceBeastWarrior: boolean
    isRaceDinosaur: boolean
    isRaceFish: boolean
    isRaceSeaeprent: boolean
    isRaceReptile: boolean
    isRacePsychro: boolean
    isRaceDevine: boolean
    isRaceCreatorgod: boolean
    isRaceWyrm: boolean
    isRaceCybers: boolean
}

type CardorId = Card | number;
declare class Deck {
    main: Array<CardorId>
    side: Array<CardorId>
    ex: Array<CardorId>
    classifiedMain: {CardorId: number}
    classifiedSide: {CardorId: number}
    classifiedEx: {CardorId: number}
    form: 'id' | 'card'

    classify(): Deck
    separateExFromMain(): Deck
    tranFromToCards(): Deck
    transformToID(): Deck

    static fromString(content: string): Deck
    static toString(): string
}

declare type __Environment = {
    new(local: string): __Environment
    main: Array<number>
    sets: Array<Set>
    cards: Record<number, Card>

    loadAllCards() : void
    searchCardByName(name: string): Array<number>
    getCardByName(name: string): Card | null
}

declare type _Environment = Record<string, __Environment> & __Environment
declare var Environment : _Environment

declare class replayHeader {
    static replayCompressedFlag: number
    static replayTagFlag: number
    static replayDecodedFlag: number
    static replaySinglMode: number
    static replayUniform: number

    dataSize: number
    isTag: boolean
    isCompressed: boolean
}

declare class Replay {
    static fromFile(filePath: string): Replay
    static fromBuffer(buffer: Buffer): Replay

    header: replayHeader
    hostName: string
    clientName: string
    startLp: number
    startHand: number
    drawCount: number
    opt: number
    hostDeck: Array<number>
    clientDeck: Array<number>
    decks: Array<Deck>

    isTag: boolean
    tagHostName?: string
    tagClientName?: string
    tagHostDeck?: Array<number>
    tagClientDeck?: Array<number>
}

declare class Set {
    number: number
    name: string
    originName: string
    ids: Array<number>

    includes(id: Card | number): boolean
    separateOriginNameFromName(): true
}

export {
    Deck,
    Environment,
    Card,
    replayHeader,
    Replay,
    Set,
}