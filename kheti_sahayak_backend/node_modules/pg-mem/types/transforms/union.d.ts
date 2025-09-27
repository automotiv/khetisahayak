import { IValue, _ISelection, _Transaction, _Explainer, _SelectExplanation, Stats, _IIndex, _IType } from '../interfaces-private';
import { DataSourceBase } from './transform-base';
import { nil } from '../interfaces';
import { ExprRef } from 'pgsql-ast-parser';
export declare function buildUnion(left: _ISelection, right: _ISelection): Union<any>;
interface UCol {
    name: string;
    type: _IType;
    lval: IValue;
    rval: IValue;
}
declare class Union<T = any> extends DataSourceBase<T> {
    private cols;
    private left;
    private right;
    get isExecutionWithNoResult(): boolean;
    isAggregation(): boolean;
    readonly columns: ReadonlyArray<IValue<any>>;
    private readonly colsByName;
    entropy(t: _Transaction): number;
    hasItem(raw: T, t: _Transaction): boolean;
    constructor(cols: UCol[], left: _ISelection, right: _ISelection);
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
    getColumn(column: string | ExprRef): IValue;
    getColumn(column: string | ExprRef, nullIfNotFound?: boolean): IValue | nil;
    getIndex(...forValue: IValue<any>[]): _IIndex<any> | null | undefined;
    isOriginOf(a: IValue<any>): boolean;
}
export {};
//# sourceMappingURL=union.d.ts.map