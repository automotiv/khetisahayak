import { _ISelection, _IIndex, IValue, _IType, _Transaction, _Explainer, _SelectExplanation, IndexKey, _IndexExplanation, IndexExpression, IndexOp, Stats } from '../interfaces-private';
import { nil } from '../interfaces';
import { Evaluator } from '../evaluator';
import { TransformBase } from './transform-base';
import { SelectedColumn, Expr, ExprRef } from 'pgsql-ast-parser';
export declare function buildSelection(on: _ISelection, select: SelectedColumn[] | nil): _ISelection<any> | Selection<any>;
export declare function columnEvaluator(this: void, on: _ISelection, id: string, type: _IType): Evaluator<any>;
export interface CustomAlias {
    val: IValue;
    as?: string;
    expr?: Expr;
}
export declare class Selection<T = any> extends TransformBase<T> implements _ISelection<T> {
    private columnIds;
    private columnsOrigin;
    private columnMapping;
    private indexCache;
    private columnsById;
    private symbol;
    readonly columns: IValue[];
    isAggregation(): boolean;
    constructor(base: _ISelection, _columns: (SelectedColumn | CustomAlias)[]);
    private refColumn;
    stats(t: _Transaction): Stats | null;
    enumerate(t: _Transaction): Iterable<T>;
    build(item: any, t: _Transaction): T;
    hasItem(value: T, t: _Transaction): boolean;
    getColumn(column: string | ExprRef): IValue;
    getColumn(column: string | ExprRef, nullIfNotFound?: boolean): IValue | nil;
    getIndex(val: IValue): _IIndex | nil;
    explain(e: _Explainer): _SelectExplanation;
}
export declare class SelectionIndex<T> implements _IIndex<T> {
    readonly owner: Selection<T>;
    private base;
    constructor(owner: Selection<T>, base: _IIndex);
    stats(t: _Transaction, key?: IndexKey): Stats | null;
    iterateKeys(t: _Transaction): Iterable<IndexKey> | null;
    get expressions(): IndexExpression[];
    entropy(op: IndexOp): number;
    eqFirst(rawKey: IndexKey, t: _Transaction): any;
    enumerate(op: IndexOp): Iterable<T>;
    explain(e: _Explainer): _IndexExplanation;
}
//# sourceMappingURL=selection.d.ts.map