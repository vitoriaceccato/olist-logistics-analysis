# 📦 Olist Logistics Delay Analysis

## 🎯 Objective

Identify and quantify structural drivers of delivery delays across ~96k delivered orders, prioritizing business impact at route level.

---

## 🧠 Approach

- Correct grain definition (1 row = 1 delivered order)
- Lead time calculation and validation
- Process decomposition (approval → dispatch → transport)
- Outlier detection using IQR
- Route-level impact prioritization (absolute impact vs global benchmark)
- Statistical validation using MAE

---

## 📊 Key Findings

1. **Transport is the main bottleneck**, presenting the highest mean (9.28 days) and variance among all stages.

2. ~**4.4% of delivered orders exceed 30 days**, based on IQR outlier detection — indicating that delays are concentrated in the tail rather than evenly distributed.

3. **Geography is a structural driver of delay**:
   - North: 11.8% delay rate  
   - Northeast: 8.22%  
   - Southeast: 1.71%  

4. **Interstate routes show nearly 9x higher probability of extreme delay** compared to intrastate routes (3.9% vs 0.4%).

5. **SP is the critical logistics hub**:
   All top critical routes by excess delay originate from São Paulo (e.g., SP → RJ, SP → BA, SP → PA, SP → CE).

6. **Route (origin → destination) explains delay better than isolated origin or destination**:
   - Route MAE: 0.0465  
   - Destination MAE: 0.0496  
   - Origin MAE: 0.0516  

---

## 🧩 Why Absolute Impact Matters

Some routes have very high relative risk (lift), but the largest business impact comes from routes that combine:

- High volume  
- Above-benchmark delay rate  

Example:
SP → RJ generates significantly more **excess delays** than SP → PA, despite SP → PA having higher relative lift.

Business prioritization should focus on **excess delays vs global benchmark**, not only percentages.

---

## ✅ Executive Recommendations

1. **Prioritize operational improvements / SLA review on SP → RJ and SP → BA**
   - High volume + high excess delays.

2. **Review logistics structure for SP → North/Northeast routes**
   - Evaluate carrier performance, routing strategy, hub allocation, and ETA calibration.

3. **Implement continuous route-level monitoring**
   - Track excess delays against global benchmark to guide prioritization.

---

## 🏆 Strategic Conclusion

Delivery delays are structural to the logistics network rather than isolated regional issues.

The strongest explanatory factor is the **route (origin → destination)**, not individual states in isolation.

Prioritizing high-impact routes generates greater business value than acting at state level.

---

## 🛠 Tools & Techniques

SQL (DuckDB)  
Relational modeling  
Descriptive statistics  
IQR outlier detection  
Absolute impact prioritization  
Mean Absolute Error (MAE)
