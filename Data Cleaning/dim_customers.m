let
    // Extracted the data from the Customer Lookup CSV file.
    Source = Csv.Document(File.Contents("your_file_path.csv"),[Delimiter=",", Columns=13, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Data cleaning and schema initialization to ensure consistency.
    #"--- Data Ingestion & Cleaning" = "",

    // Promoted the first row to headers for proper field identification.
    Promoted_Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // Assigned initial data types for the first phase of cleaning.
    Changed_Type_Initial = Table.TransformColumnTypes(Promoted_Headers,{{"CustomerKey", Int64.Type}, {"Prefix", type text}, {"FirstName", type text}, {"LastName", type text}, {"BirthDate", type date}, {"MaritalStatus", type text}, {"Gender", type text}, {"EmailAddress", type text}, {"AnnualIncome", Int64.Type}, {"TotalChildren", Int64.Type}, {"EducationLevel", type text}, {"Occupation", type text}, {"HomeOwner", type text}}),

    // Removed rows with errors in the primary key to maintain data integrity.
    Removed_Errors_Initial = Table.RemoveRowsWithErrors(Changed_Type_Initial, {"CustomerKey"}),

    // Removed duplicate records based on CustomerKey and EmailAddress to ensure unique customer entities.
    Removed_Duplicates_Key = Table.Distinct(Removed_Errors_Initial, {"CustomerKey"}),
    Removed_Duplicates_Email = Table.Distinct(Removed_Duplicates_Key, {"EmailAddress"}),

    // Excluded blank rows across the dataset.
    Removed_Blank_Rows = Table.SelectRows(Removed_Duplicates_Email, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}))),


    // Standardizing text formats and applying bulk transformations.
    #"--- Text Formatting & Normalization" = "",

    // Applied Capitalization and Lowercase transformations to name and email fields.
    Capitalized_Names = Table.TransformColumns(Removed_Blank_Rows,{{"Prefix", Text.Proper, type text}, {"LastName", Text.Proper, type text}, {"FirstName", Text.Proper, type text}}),
    Lowercased_Email = Table.TransformColumns(Capitalized_Names,{{"EmailAddress", Text.Lower, type text}}),

    // Temporarily cast columns to text to perform a universal Trim operation on all fields.
    Cast_To_Text_For_Trim = Table.TransformColumnTypes(Lowercased_Email, {{"TotalChildren", type text}, {"AnnualIncome", type text}, {"BirthDate", type text}, {"CustomerKey", type text}}, "en-US"),

    // Collapsed 13 individual Trim steps into a single transformation.
    Trimmed_Text_Bulk = Table.TransformColumns(Cast_To_Text_For_Trim, {
        {"HomeOwner", Text.Trim, type text}, {"Occupation", Text.Trim, type text}, {"EducationLevel", Text.Trim, type text}, 
        {"TotalChildren", Text.Trim, type text}, {"AnnualIncome", Text.Trim, type text}, {"EmailAddress", Text.Trim, type text}, 
        {"Gender", Text.Trim, type text}, {"MaritalStatus", Text.Trim, type text}, {"BirthDate", Text.Trim, type text}, 
        {"LastName", Text.Trim, type text}, {"FirstName", Text.Trim, type text}, {"Prefix", Text.Trim, type text}, {"CustomerKey", Text.Trim, type text}
    }),

    // Reverted columns back to their functional data types after trimming.
    Changed_Type_Post_Trim = Table.TransformColumnTypes(Trimmed_Text_Bulk,{{"CustomerKey", Int64.Type}, {"BirthDate", type date}, {"AnnualIncome", type number}, {"TotalChildren", Int64.Type}}),


    // Standardizing categorical values and finalizing the table structure.
    #"--- Value Standardization & Schema Finalization" = "",

    // Collapsed 9 ReplaceValue steps into a single iterative process for efficiency.
    Apply_Bulk_Replacements = List.Accumulate(
        {
            {"MaritalStatus", "M", "Married"}, {"MaritalStatus", "S", "Single"},
            {"Gender", "M", "Male"}, {"Gender", "Maleale", "Male"}, {"Gender", "F", "Female"}, {"Gender", "Femaleemale", "Female"},
            {"HomeOwner", "Y", "Yes"}, {"HomeOwner", "N", "No"}, {"HomeOwner", "y", "Yes"}
        }, 
        Changed_Type_Post_Trim, 
        (state, current) => Table.ReplaceValue(state, current{1}, current{2}, Replacer.ReplaceText, {current{0}})
    ),

    // Combined name components into a single Full Name field.
    Merged_Full_Name = Table.CombineColumns(Apply_Bulk_Replacements,{"Prefix", "FirstName", "LastName"},Combiner.CombineTextByDelimiter(" ", QuoteStyle.None),"Full Name"),

    // Renamed CustomerKey to align with the data model naming convention.
    Renamed_Customer_Key = Table.RenameColumns(Merged_Full_Name,{{"CustomerKey", "Customer Key"}}),

    // Filtered out any remaining null values in the primary key column.
    Filtered_Null_Keys = Table.SelectRows(Renamed_Customer_Key, each ([Customer Key] <> null)),

    // Removed the Email column as it is not required for the final analysis.
    Removed_Email_Column = Table.RemoveColumns(Filtered_Null_Keys,{"EmailAddress"}),

    // Finalized column names for business stakeholder clarity.
    Final_Renamed_Columns = Table.RenameColumns(Removed_Email_Column,{{"BirthDate", "Birth Date"}, {"MaritalStatus", "Marital Status"}, {"AnnualIncome", "Annual Income"}, {"TotalChildren", "Total Children"}, {"EducationLevel", "Edu Level"}, {"HomeOwner", "Home Owner"}})

in
    Final_Renamed_Columns
