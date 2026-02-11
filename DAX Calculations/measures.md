### Key Metrics and Formulas:

* **Total Sales**: Sum of sales revenue from the fact table.
  * **Formula**: `SUM('Fact Sales'[Sales Amount])`
  * **Formatting**: `$#,0.00;($#,0.00);$#,0.00`


* **Total Cost**: Total cost of goods sold aggregated from sales records.
  * **Formula**: `SUM('Fact Sales'[Total Cost])`
  * **Formatting**: `$#,0.###############`


* **Profit**: Total revenue minus total costs.
  * **Formula**: `[Total Sales] - [Total Cost]`
  * **Formatting**: `$#,0.0`


* **Profit Margin**: The percentage of revenue that exceeds costs.
  * **Formula**: `[Profit] / [Total Sales]`
  * **Formatting**: `0.00%`


* **Total Orders**: Total number of unique order transactions.
  * **Formula**: `DISTINCTCOUNT('Fact Sales'[Order Number])`
  * **Formatting**: `0`


* **Total Customers**: Count of unique customers who placed orders.
  * **Formula**: `DISTINCTCOUNT('Fact Sales'[Customer Key])`
  * **Formatting**: `0`


* **Total Qty Sold**: Sum of all units sold across all transactions.
  * **Formula**: `SUM('Fact Sales'[Quantity])`
  * **Formatting**: `0`


* **AOV (Average Order Value)**: The average revenue generated per unique order.
  * **Formula**: `DIVIDE([Total Sales], [Total Orders], 0)`
  * **Formatting**: `$#,0.0`


* **Return Amount**: Sum of revenue lost due to returned items.
  * **Formula**: `SUM('Fact Return'[Return Amount])`
  * **Formatting**: `$#,0.0`


* **Return Qty**: Total number of items returned.
  * **Formula**: `SUM('Fact Return'[Return Quantity])`
  * **Formatting**: `#,0`


* **Return%**: The ratio of units returned to total units sold.
  * **Formula**: `[Return Qty] / [Total Qty Sold]`
  * **Formatting**: `0.00%`


* **Recency**: Number of days since the most recent order was placed.
  * **Formula**: `DATEDIFF(MAX('Fact Sales'[Order Date]), TODAY(), DAY)`
  * **Formatting**: `0`



### Month-over-Month (MoM) Growth Metrics:

These measures calculate the percentage change compared to the previous month using `DATEADD`.

### Key Metrics and Formulas (Formatted):

* **MoM Growth% (Sales)**:

```dax
VAR _pm = CALCULATE([Total Sales], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([Total Sales] - _pm), _pm)
```

* **MoM Growth% (Cost)**:

```dax
VAR _pm = CALCULATE([Total Cost], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([Total Cost] - _pm), _pm)
```

* **MoM Growth% (Profit)**:

```dax
VAR _pm = CALCULATE([Profit], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([Profit] - _pm), _pm)
```

* **MoM Growth% (Orders)**:

```dax
VAR _pm = CALCULATE([Total Orders], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([Total Orders] - _pm), _pm)
```

* **MoM Growth% (Qty Sold)**:

```dax
VAR _pm = CALCULATE([Total Qty Sold], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([Total Qty Sold] - _pm), _pm)
```

* **MoM Growth% (AOV)**:

```dax
VAR _pm = CALCULATE([AOV], DATEADD('Dim Date'[Date], -1, MONTH))
RETURN 
    DIVIDE(([AOV] - _pm), _pm)
```

### KPI Formatting & Logic:

* **Growth Indicators**: All MoM metrics use a custom format string to display an **Up Arrow** (🟢) for positive growth and a **Down Arrow** (🔴) for negative growth.
  * **Formatting**: `UNICHAR(129157) & " 0.00%; " & UNICHAR(129158) & " 0.00%; " & "0.00%"`
  
* **Color Logic**: KPI Color measures (e.g., `Color(Sales)`) return specific Hex codes (`#6FB679` for Green, `#DE6A73` for Red) based on whether growth is positive or negative, allowing for dynamic conditional formatting in dashboard visuals.
  * **Formula**:
  ```dax
  Color(Sales) = IF( [MoM Growth% (Sales)] >= 0, "#6FB679", "#DE6A73" )
  ```
