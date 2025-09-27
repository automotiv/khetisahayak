import { _IIndex, IValue, _ITable, _Transaction, _Explainer, _IndexExplanation, IndexOp, IndexKey, Stats } from '../interfaces-private';
interface IndexSubject<T> {
    readonly size: number;
    readonly column: IValue;
    byColumnValue(columnValue: string, t: _Transaction): T[];
}
export declare class CustomIndex<T> implements _IIndex<T> {
    readonly onTable: _ITable<T>;
    private subject;
    readonly expressions: IValue<any>[];
    explain(e: _Explainer): _IndexExplanation;
    constructor(onTable: _ITable<T>, subject: IndexSubject<T>);
    get indexName(): string;
    entropy(): number;
    stats(t: _Transaction, key?: IndexKey): Stats | null;
    iterateKeys(): null;
    add(raw: any): void;
    eqFirst([key]: any, t: _Transaction): T | null;
    enumerate(op: IndexOp): Iterable<T>;
    eq([rawKey]: any, t: _Transaction): Iterable<any>;
    nin(keys: any[][], t: _Transaction): Generator<T, void, unknown>;
    neq([rawKey]: any, t: _Transaction): Generator<T, void, unknown>;
    gt(rawKey: any, t: _Transaction): Iterable<any>;
    lt(rawKey: any, t: _Transaction): Iterable<any>;
    ge(rawKey: any, t: _Transaction): Iterable<any>;
    le(rawKey: any, t: _Transaction): Iterable<any>;
    outside(lo: IndexKey, hi: IndexKey, t: _Transaction): Iterable<T>;
    inside(lo: IndexKey, hi: IndexKey, t: _Transaction): Iterable<T>;
}
export {};
//# sourceMappingURL=custom-index.d.ts.map