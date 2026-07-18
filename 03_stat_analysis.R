# Статистический анализ признаков QE-триажа (zh-ru MT)
#
# Вход: features.csv из 02_mt_triage_qe_colab.ipynb (шаг 4) — признаки без
# эталона (jieba, длины, NER-несоответствия, LaBSE similarity src<->mt) плюс
# quality_score/needs_edit, полученные на этапе авторазметки (шаг 3).
#
# Если рядом со скриптом нет features.csv (ноутбук ещё не запускали),
# используется data/sample_features.csv — синтетический пример с той же
# структурой, чтобы скрипт можно было проверить сразу.

features_path <- Sys.getenv("FEATURES_CSV", unset = "features.csv")
if (!file.exists(features_path)) {
  message("features.csv не найден рядом со скриптом, использую пример data/sample_features.csv")
  features_path <- file.path("data", "sample_features.csv")
}

df <- read.csv(features_path)
feature_cols <- setdiff(names(df), c("quality_score", "needs_edit"))

cat("Файл:", features_path, "\n")
cat("Строк:", nrow(df), "\n")
cat("Признаки:", paste(feature_cols, collapse = ", "), "\n\n")

## --- 1. Корреляция признаков с quality_score -----------------------------

cat("=== Корреляция Пирсона с quality_score ===\n")
cor_results <- data.frame(
  feature = feature_cols,
  pearson_r = NA_real_,
  p_value = NA_real_
)
for (i in seq_along(feature_cols)) {
  test <- cor.test(df[[feature_cols[i]]], df$quality_score)
  cor_results$pearson_r[i] <- unname(test$estimate)
  cor_results$p_value[i] <- test$p.value
}
cor_results <- cor_results[order(-abs(cor_results$pearson_r)), ]
print(cor_results, row.names = FALSE)

## --- 2. t-test: признаки в группах accept vs needs_edit ------------------

cat("\n=== t-test: accept (needs_edit=0) vs needs_edit=1 ===\n")
for (col in feature_cols) {
  good <- df[df$needs_edit == 0, col]
  bad <- df[df$needs_edit == 1, col]
  if (length(good) > 1 && length(bad) > 1) {
    tt <- t.test(good, bad)
    cat(sprintf("%-20s t=%6.2f  p=%.4f\n", col, unname(tt$statistic), tt$p.value))
  } else {
    cat(sprintf("%-20s недостаточно данных в одной из групп\n", col))
  }
}

## --- 3. Линейная регрессия: quality_score ~ признаки ---------------------

cat("\n=== Линейная регрессия: quality_score ~ . ===\n")
lm_formula <- as.formula(paste("quality_score ~", paste(feature_cols, collapse = " + ")))
lm_fit <- lm(lm_formula, data = df)
print(summary(lm_fit))

## --- 4. Логистическая регрессия: needs_edit ~ признаки --------------------

cat("\n=== Логистическая регрессия: needs_edit ~ . ===\n")
glm_formula <- as.formula(paste("needs_edit ~", paste(feature_cols, collapse = " + ")))
glm_fit <- glm(glm_formula, data = df, family = binomial)
print(summary(glm_fit))

## --- 5. ANOVA по группам needs_edit для каждого признака ------------------

cat("\n=== ANOVA (needs_edit как фактор) по признакам ===\n")
for (col in feature_cols) {
  aov_fit <- aov(as.formula(paste(col, "~ factor(needs_edit)")), data = df)
  cat("--", col, "--\n")
  print(summary(aov_fit))
}

## --- 6. Графики ------------------------------------------------------------

dir.create("plots", showWarnings = FALSE)

png("plots/correlation_barplot.png", width = 800, height = 500)
par(mar = c(5, 12, 4, 2))
barplot(
  rev(cor_results$pearson_r),
  names.arg = rev(cor_results$feature),
  horiz = TRUE, las = 1,
  main = "Корреляция признаков с quality_score",
  xlab = "Pearson r"
)
dev.off()

for (col in feature_cols) {
  png(file.path("plots", paste0("box_", col, ".png")), width = 600, height = 500)
  boxplot(
    as.formula(paste(col, "~ needs_edit")), data = df,
    names = c("accept", "needs_edit"),
    main = col, xlab = "", ylab = col
  )
  dev.off()
}

cat("\nГрафики сохранены в plots/\n")
