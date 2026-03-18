## 1) Context DFD (Very High Level)

```mermaid
flowchart LR
  E1[Customer]
  E2[Employee]
  E3[Admin]
  E4[Telegram Bot/Channel]
  P0((Order Management System))

  E1 -->|view menu + place order| P0
  P0 -->|order result/status| E1

  E2 -->|assign/complete/cancel action| P0
  E4 -->|telegram callbacks| P0
  P0 -->|order message| E4

  E3 -->|manage data + reports| P0
  P0 -->|dashboards/exports| E3
```

## 2) Level 1 DFD (Customer + Employee Order Flow)

```mermaid
---
config:
  layout: fixed
  theme: redux
---
flowchart LR
    E1["Customer"] --> P1(("① Browse Menu")) & P2(("② Transaction pre-process"))
    P1 --> E1
    P2 --> P3(("③ Apply Promotion & Price"))
    P3 --> P4(("④ Create Pending Transaction"))
    P4 --> P5(("⑤ Send to Telegram"))
  P8(("⑥ Receive Employee Telegram Action"))
    P5 --> E3["Telegram Channel"]
  E2["Employee"] -- assign/complete/cancel action --> P8
  E3 -- callback payload --> P8
  P8 -- assign payload --> P6(("⑦ Assign Employee"))
  P8 -- finalize payload --> P7(("⑧ Finalize Transaction"))
    P1 -- product list --> D1[("products")]
    P1 -- latest price --> D2[("product_prices")]
    P1 -- category info --> D3[("product_categories")]
    P3 -- active promotion --> D5[("promotions")]
    P3 -- promotion progression --> D6[("user_promotions_tracker")]
    P2 -- customer profile --> D4[("customers")]
    P2 -- table validation --> D7[("seating_tables")]
    P2 -- pending count by table/status --> D8[("transactions")]
    P3 -- selected products --> D1
    P3 -- product pricing --> D2
    P4 -- transaction row --> D8
    P4 -- order items --> D9[("products_transactions")]
    P6 -- employee data to assign to transaction --> D8
    P7 -- status update --> D8

     P1:::orderStep
     P2:::orderStep
     P3:::orderStep
     P4:::orderStep
     P5:::orderStep
    P8:::orderStep
     P6:::orderStep
     P7:::orderStep
    classDef orderStep fill:#FFE082,stroke:#E65100,stroke-width:2px,color:#000000
    style E1 stroke:#D50000,color:#D50000
    style E3 stroke:#D50000,color:#D50000
    style E2 stroke:#D50000,color:#D50000
```

## 3) Level 1 DFD (Admin Scope)

```mermaid
flowchart TB
  E1[Admin]
  P0((① Admin Request))
  P1((② Manage Data & Reporting))

  D1[(users)]
  D2[(transactions)]
  D3[(products)]
  D4[(product_categories)]
  D5[(product_prices)]
  D6[(promotions)]
  D7[(employees)]
  D8[(seating_tables)]
  D9[(inventories)]
  D10[(inventory_movements)]

  E1 -->|manage + view/export| P0
  P0 --> P1
  P1 -->|user records + export filters| D1
  P1 -->|transaction records + export range| D2
  P1 -->|product CRUD data| D3
  P1 -->|category CRUD data| D4
  P1 -->|price update history| D5
  P1 -->|promotion rules + status| D6
  P1 -->|employee profile/status| D7
  P1 -->|table setup (table_number,seating_count)| D8
  P1 -->|inventory master (name,note,image)| D9
  P1 -->|inventory movement logs (type,qty,time)| D10

  classDef orderStep fill:#FFE082,stroke:#E65100,stroke-width:2px,color:#000000;
  class P0,P1 orderStep;
```