import { DataSourceBase } from '../../transforms/transform-base';
import { _ISelection, _ITable, _Transaction, IValue, _IIndex, _Explainer } from '../../interfaces-private';
import { InsertStatement, UpdateStatement, DeleteStatement, SetStatement, ExprRef } from 'pgsql-ast-parser';
declare type MutationStatement = InsertStatement | UpdateStatement | DeleteStatement;
export declare abstract class MutationDataSourceBase<T> extends DataSourceBase<T> {
    protected table: _ITable;
    protected mutatedSel: _ISelection;
    static readonly affectedRows: unique symbol;
    /** Perform the mutation, and returns the affected elements */
    protected abstract performMutation(t: _Transaction): T[];
    private returningRows?;
    private returning?;
    private mutationResult;
    get isExecutionWithNoResult(): boolean;
    isAggregation(): boolean;
    get columns(): readonly IValue<any>[];
    constructor(table: _ITable, mutatedSel: _ISelection, p: MutationStatement);
    private _doExecuteOnce;
    enumerate(t: _Transaction): Iterable<any>;
    entropy(t: _Transaction): number;
    getColumn(column: string | ExprRef, nullIfNotFound?: boolean | undefined): IValue<any>;
    hasItem(value: any, t: _Transaction): boolean;
    getIndex(forValue: IValue<any>): _IIndex<any> | null | undefined;
    explain(e: _Explainer): never;
    isOriginOf(a: IValue<any>): boolean;
    stats(t: _Transaction): null;
}
export declare type Setter = (t: _Transaction, target: any, source: any) => void;
export declare function createSetter(this: void, setTable: _ITable, setSelection: _ISelection, _sets: SetStatement[]): Setter;
export {};
//# sourceMappingURL=mutation-base.d.ts.map