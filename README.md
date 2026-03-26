# 📦 Olist Logistics Delay Analysis  

## 🎯 Business Problem
Delivery delays were impacting operational efficiency and customer experience. The goal was to identify key drivers of lead time variability and support data-driven logistics decisions.

---

## 📊 Dashboard Preview
Power BI dashboard summarizing delivery performance, delay distribution, and route-level bottlenecks across ~96K orders.

<img width="730" height="403" alt="dashboard_overview" src="https://github.com/user-attachments/assets/49775ed8-7be4-4a32-8149-c6896a60ed9d" />

---

## 🎯 Business Impact
- Identified key operational bottlenecks affecting delivery performance  
- Supported data-driven decisions for route optimization and logistics planning  
- Simulated improvements reducing delivery variability by ~12%  


## 📊 Dataset  
~96K delivered orders  
Grain: 1 row = 1 delivered order  
Primary metric: Lead time (purchase → delivery)

---

## 🔎 Core Findings  

### 1️⃣ Transport is the structural bottleneck  
Highest mean (9.28 days) and highest variability among all process stages.

### 2️⃣ Delays are tail-driven, not average-driven  
4.4% of orders exceed 30 days (IQR-based threshold).  
Performance instability is concentrated in extreme cases rather than the core flow.

### 3️⃣ Geography materially increases delay risk  
Interstate orders show ~9x higher extreme-delay probability  
(3.9% vs 0.4% intrastate).

North (11.8%) and Northeast (8.2%) exhibit structurally elevated delay rates.

### 4️⃣ Route concentration drives operational impact  
Top excess-delay routes originate from São Paulo:

- SP → RJ  
- SP → BA  
- SP → PA  
- SP → CE  

High volume combined with above-benchmark delay rates generates the greatest operational burden.

### 5️⃣ Route explains delays better than isolated geography  
MAE comparison:

- Route (origin + destination): **0.0465**  
- Destination only: 0.0496  
- Origin only: 0.0516  

Delays are best explained at the route level rather than by origin or destination alone.

---

## 🏆 Strategic Conclusion  

- Route-level optimization should be prioritized over state-level interventions, as it delivers higher impact on reducing delivery delays and improving logistics performance.

- Focusing on high-volume, high-delay routes enables more effective resource allocation and operational efficiency gains.

---

## 📁 Project Structure
```text
olist-logistics-analysis
│
├── sql/
│   ├── 01_olist_logistics_portfolio.sql
│   └── 02_lead_time_metrics.sql
│
├── dashboard/
│   └── olist_logistics_dashboard.pbix
│
├── images/
│   └── dashboard_overview.png
│
└── README.md
```

---

## 🛠 Methods  

- SQL (DuckDB)  
- Relational modeling  
- IQR-based outlier detection  
- Excess delays vs global benchmark  
- Mean Absolute Error (MAE) validation

---

## 📈 Skills Demonstrated

- SQL analytics
- Logistics performance analysis
- Outlier detection using IQR
- Route-level operational diagnostics
- Data storytelling for operational decision-making
