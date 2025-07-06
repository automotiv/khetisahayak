import { _ISelection, IValue, _IIndex, _Transaction, _SelectExplanation, _Explainer, IndexExpression, IndexOp, IndexKey, _IndexExplanation, Stats, _IAlias } from '../interfaces-private';
import { nil } from '../interfaces';
import { DataSourceBase } from './transform-base';
import { ExprRef, JoinClause } from 'pgsql-ast-parser';
import { SELECT_ALL } from '../execution/clean-results';
interface JoinRaw<TLeft, TRight> {
    '>restrictive': TLeft;
    '>joined': TRight;
}
interface JoinStrategy {
    iterate: _ISelection;
    iterateSide: 'joined' | 'restrictive';
    joinIndex: _IIndex<any>;
    onValue: IValue;
    othersPredicate?: IValue<any>;
}
export declare class JoinSelection<TLeft = any, TRight = any> extends DataSourceBase<JoinRaw<TLeft, TRight>> {
    readonly restrictive: _ISelection<TLeft>;
    readonly joined: _ISelection<TRight>;
    readonly innerJoin: boolean;
    get isExecutionWithNoResult(): boolean;
    private _columns;
    private seqScanExpression;
    private joinId;
    private columnsMappingParentToThis;
    private indexOnRestrictingTableByValue;
    private indexCache;
    strategies: JoinStrategy[];
    private building;
    private ignoreDupes?;
    private mergeSelect?;
    isOriginOf(a: IValue<any>): boolean;
    get columns(): IValue<any>[];
    entropy(t: _Transaction): number;
    constructor(restrictive: _ISelection<TLeft>, joined: _ISelection<TRight>, on: JoinClause, innerJoin: boolean);
    private wrap;
    listSelectableIdentities(): Iterable<IValue>;
    private fetchOnStrategies;
    private fetchUsingStrategies;
    private fetchAndStrategies;
    private fetchEqStrategyOn;
    getColumn(column: string | ExprRef): IValue;
    getColumn(column: string | ExprRef, nullIfNotFound?: boolean): IValue | nil;
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<any>;
    selectAlias(alias: string): _IAlias | nil;
    iterateCatastrophicItem(item: any, others: any[], side: 'joined' | 'restrictive', t: _Transaction): Generator<any, void, unknown>;
    private builder;
    iterateStrategyItem(item: any, strategy: JoinStrategy, t: _Transaction): Generator<any, void, unknown>;
    buildItem(l: TLeft, r: TRight): {
        '>joined': TRight;
        '>restrictive': TLeft;
        [SELECT_ALL]: () => any;
    };
    private merge;
    hasItem(value: JoinRaw<TLeft, TRight>): boolean;
    getIndex(forValue: IValue<any>): _IIndex<any> | nil;
    explain(e: _Explainer): _SelectExplanation;
}
export declare class JoinIndex<T> implements _IIndex<T> {
    readonly owner: JoinSelection<T>;
    private base;
    constructor(owner: JoinSelection<T>, base: _IIndex);
    get expressions(): IndexExpression[];
    stats(t: _Transaction, key?: IndexKey): Stats | null;
    iterateKeys(): null;
    entropy(op: IndexOp): number;
    eqFirst(rawKey: IndexKey, t: _Transaction): T | null;
    private chooseStrategy;
    enumerate(op: IndexOp): Iterable<T>;
    explain(e: _Explainer): _IndexExplanation;
}
export {};
//# sourceMappingURL=join.d.ts.map