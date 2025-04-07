
## 🔍 Key Analyses
1. **Proximity Metrics**  
   - Calculated nearest railways/airports to tourist sites using PostGIS:
     ```sql
     SELECT 
       attractions.name,
       ST_Distance(
         ST_Transform(attractions.geom, 3857), 
         ST_Transform(infra.geom, 3857)
       )/1000 AS distance_km
     FROM attractions
     CROSS JOIN LATERAL (
       SELECT infra.geom 
       FROM railways AS infra
       ORDER BY attractions.geom <-> infra.geom
       LIMIT 1
     ) AS infra;
     ```

2. **Density Mapping**  
   - Generated heatmaps to visualize spatial clustering of:
     - Cherry blossom sites (Spring)
     - Firework festivals (Summer)  
     - Ski resorts (Winter)

3. **Accessibility Scoring**  
   - Ranked regions by transport connectivity using choropleth maps.

## 🎯 Skills Demonstrated
✅ Spatial SQL (PostGIS)  
✅ High-dimensional data processing  
✅ Spatio-temporal pattern detection  
✅ Statistical visualization  

## 📄 Academic Relevance
This project showcases techniques transferable to **hyperspectral data analysis**:
- Handling correlated spatial structures (analogous to spectral bands)
- Dimensionality reduction (KDE → PCA)
- Clustering for pattern detection (DBSCAN → k-means)

## 🔗 Data Sources
- OpenStreetMap (via Overpass Turbo)
- Japan National Tourism Organization (JNTO)

---
**👨💻 Author**: Saihan Saiyed  
**📧 Contact**: saiyedsaihan@gmail.com  
**🏫 Institution**: Maynooth University (MSc Data Science)
