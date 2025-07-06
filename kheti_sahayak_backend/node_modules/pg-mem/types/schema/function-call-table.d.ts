import { _Transaction, IValue, _Explainer, _IIndex, _SelectExplanation, Stats } from '../interfaces-private';
import { RecordCol } from '../datatypes';
import { DataSourceBase } from '../transforms/transform-base';
export declare class FunctionCallTable extends DataSourceBase<any> {
    private evaluator;
    readonly columns: readonly IValue<any>[];
    private readonly colsByName;
    private symbol;
    get isExecutionWithNoResult(): boolean;
    constructor(cols: readonly RecordCol[], evaluator: IValue);
    entropy(t: _Transaction): number;
    enumerate(t: _Transaction): Iterable<any>;
    hasItem(value: any, t: _Transaction): boolean;
    getColumn(column: string, nullIfNotFound?: boolean | undefined): IValue<any>;
    getIndex(forValue: IValue<any>): _IIndex<any> | null | undefined;
    isOriginOf(value: IValue<any>): boolean;
    explain(e: _Explainer): _SelectExplanation;
    stats(t: _Transaction): Stats | null;
}
//# sourceMappingURL=function-call-table.d.ts.map