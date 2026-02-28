# 📦 Olist Logistics Delay Analysis

## 🎯 Business Question  
What structurally drives extreme delivery delays, and where should operations prioritize intervention?

---

## 📊 Dataset  
~96K delivered orders  
Grain: 1 row = 1 delivered order  
Metric: Lead time (purchase → delivery)

---

## 🔎 Core Findings

### 1️⃣ Transport is the bottleneck  
Highest mean (9.28 days) and highest variance across process stages.

### 2️⃣ Delays are tail-driven  
4.4% of orders exceed 30 days (IQR-based threshold).  
Performance instability is concentrated in extreme cases, not the average.

### 3️⃣ Geography materially increases risk  
Interstate orders have ~9x higher extreme delay probability  
(3.9% vs 0.4% intrastate).

North (11.8%) and Northeast (8.2%) show structurally higher delay rates.

### 4️⃣ Route concentration drives impact  
Top excess-delay routes all originate from São Paulo:

SP → RJ  
SP → BA  
SP → PA  
SP → CE  

High volume + above-benchmark delay rate = highest operational impact.

### 5️⃣ Route explains delay better than isolated geography  
MAE comparison:

Route (origin + destination): **0.0465**  
Destination only: 0.0496  
Origin only: 0.0516  

Delays are best explained at route level.

---

## 🏆 Strategic Conclusion

Delivery delays are structural to the logistics network.

Route-level prioritization generates higher business impact than state-level intervention.

---

## 🛠 Methods

SQL (DuckDB)  
Relational modeling  
IQR outlier detection  
Excess delay vs global benchmark  
Mean Absolute Error (MAE) validation
