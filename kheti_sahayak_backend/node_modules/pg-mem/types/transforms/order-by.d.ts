import { IValue, _ISelection, _Transaction, _Explainer, _SelectExplanation, Stats, _IAggregation } from '../interfaces-private';
import { FilterBase } from './transform-base';
import { OrderByStatement, ExprCall } from 'pgsql-ast-parser';
export declare function buildOrderBy(on: _ISelection, order: OrderByStatement[]): OrderBy<any>;
declare class OrderBy<T> extends FilterBase<any> implements _IAggregation {
    private selection;
    order: {
        by: IValue<any>;
        order: 'ASC' | 'DESC';
        nullsLast: boolean;
    }[];
    get index(): null;
    isAggregation(): boolean;
    getAggregation(name: string, call: ExprCall): IValue;
    checkIfIsKey(got: IValue<any>): IValue<any>;
    private get asAggreg();
    entropy(t: _Transaction): number;
    hasItem(raw: T, t: _Transaction): boolean;
    constructor(selection: _ISelection<T>, order: OrderByStatement[]);
    stats(t: _Transaction): Stats | null;
    getIndex(...forValue: IValue<any>[]): import("../interfaces").nil | import("../interfaces-private")._IIndex<any>;
    enumerate(t: _Transaction): Iterable<T>;
    explain(e: _Explainer): _SelectExplanation;
}
export {};
//# sourceMappingURL=order-by.d.ts.map