# test_project_cl_2026
Это тестовый проект

## Триаж машинного перевода для постредактирования (QE), zh → ru

`02_mt_triage_qe_colab.ipynb` — стартовый Colab-ноутбук пайплайна: сбор zh-ru пар (UN Parallel Corpus), генерация MT (Helsinki-NLP/opus-mt-zh-ru), авторазметка качества (chrF + LaBSE) для обучения, признаки без эталона (jieba, длины, NER-несоответствия, cross-lingual LaBSE similarity), статистика (корреляции, t-test) и ML (регрессия качества + классификация accept/edit на RandomForest/GradientBoosting).

Открыть в Google Colab: загрузите файл `02_mt_triage_qe_colab.ipynb` через File → Upload notebook, либо откройте репозиторий напрямую через File → Open notebook → GitHub.
