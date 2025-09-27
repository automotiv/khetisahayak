import { IValue, _IType } from '../interfaces-private';
import { DataType, IType, nil } from '../interfaces';
import { Evaluator } from '../evaluator';
import { TypeBase } from './datatype-base';
declare class NullType extends TypeBase<null> {
    get primary(): DataType;
    doCast(value: Evaluator<any>, to: _IType): Evaluator<any>;
    doCanCast(to: _IType): boolean;
    doCanConvertImplicit(): boolean;
    doEquals(a: any, b: any): boolean;
    doGt(a: any, b: any): boolean;
    doLt(a: any, b: any): boolean;
    doPrefer(type: _IType): _IType<any>;
}
export declare class DefaultType extends NullType {
}
export declare const integers: ReadonlySet<DataType>;
export declare const floats: ReadonlySet<DataType>;
export declare const numbers: ReadonlySet<DataType>;
export declare const numberPriorities: Record<DataType, number>;
export declare function isNumeric(t: DataType | IType): boolean;
export declare function isInteger(t: DataType | IType): boolean;
declare class TextType extends TypeBase<string> {
    readonly len: number | null;
    private citext?;
    get name(): string;
    get primary(): DataType;
    constructor(len: number | null, citext?: boolean | undefined);
    doPrefer(to: _IType): _IType<any> | TextType | null;
    doCanConvertImplicit(to: _IType): boolean;
    doCanCast(to: _IType): boolean | nil;
    doCast(value: Evaluator<string>, to: _IType): Evaluator<string> | undefined;
    doEquals(a: string, b: string): boolean;
}
export declare class ArrayType extends TypeBase<any[]> {
    readonly of: _IType;
    private list;
    static matches(type: IType): type is ArrayType;
    get primary(): DataType;
    get name(): string;
    constructor(of: _IType, list: boolean);
    doCanCast(to: _IType): boolean | nil;
    doCast(value: Evaluator, _to: _IType): Evaluator<any>;
    toText(to: _IType, value: Evaluator): Evaluator<any>;
    toSingleColumn(to: _IType, value: Evaluator): Evaluator<any>;
    doEquals(a: any[], b: any[]): boolean;
    doGt(a: any[], b: any[]): boolean;
    doLt(a: any[], b: any[]): boolean;
    convertLiteral(elts: any): any[] | undefined;
}
export interface RecordCol {
    readonly name: string;
    readonly type: _IType;
}
/** Basic types */
export declare const Types: {
    record: (columns: RecordCol[]) => _IType<any>;
    bool: _IType<any>;
    text: (len?: number | nil) => _IType<any>;
    citext: TextType;
    timestamp: (len?: number | nil) => _IType<any>;
    timestamptz: (len?: number | nil) => _IType<any>;
    uuid: _IType<any>;
    date: _IType<any>;
    interval: _IType<any>;
    time: _IType<any>;
    timetz: _IType<any>;
    jsonb: _IType<any>;
    regtype: _IType<any>;
    regclass: _IType<any>;
    json: _IType<any>;
    null: _IType<any>;
    float: _IType<any>;
    integer: _IType<any>;
    bigint: _IType<any>;
    bytea: _IType<any>;
    point: _IType<any>;
    line: _IType<any>;
    lseg: _IType<any>;
    box: _IType<any>;
    inet: _IType<any>;
    path: _IType<any>;
    polygon: _IType<any>;
    circle: _IType<any>;
    default: _IType<any>;
};
export declare const dateTypes: ReadonlySet<DataType>;
export declare function isDateType(_type: _IType | DataType): boolean;
export declare function isGeometric(dt: DataType): boolean;
export declare const typeSynonyms: {
    [key: string]: DataType | {
        type: DataType;
        ignoreConfig: boolean;
    };
};
/** Finds a common type by implicit conversion */
export declare function reconciliateTypes(values: IValue[], nullIfNoMatch?: false): _IType;
export declare function reconciliateTypes(values: IValue[], nullIfNoMatch: true): _IType | nil;
export declare function reconciliateTypes(values: IValue[], nullIfNoMatch?: boolean): _IType | nil;
export {};
//# sourceMappingURL=datatypes.d.ts.map