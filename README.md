# 📦 Olist Logistics Delay Analysis

## 🎯 Objective

Identify structural causes of delivery delays across ~96k delivered orders from Olist marketplace data.

---

## 🧠 Approach

- Correct grain definition (1 row = 1 delivered order)
- Lead time calculation and validation
- Process decomposition (approval → dispatch → transport)
- Outlier detection using IQR
- Route-level impact prioritization
- Statistical validation using MAE

---

## 📊 Key Findings

1. **Transport is the main bottleneck**, presenting the highest mean and variance.
2. ~4.4% of orders exceed 30 days (IQR-based extreme delays).
3. Interstate routes significantly increase delay risk.
4. Route (origin → destination) explains delays better than isolated origin or destination (lowest MAE = 0.0465).

---

## 🏆 Strategic Conclusion

Delivery delays are structural to the logistics network, not isolated regional issues.

Prioritizing critical routes generates greater business impact than acting on individual states.

---

## 🛠 Tools & Techniques

SQL (DuckDB)  
Relational modeling  
Descriptive statistics  
IQR outlier detection  
Absolute impact prioritization  
Mean Absolute Error (MAE)
