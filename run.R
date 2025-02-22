#!/usr/bin/env Rscript
library(tensorflow)
library(keras3)
library(tidyverse)

# Controllo configurazione di python
print(reticulate::py_config())

# Verifica la presenza di GPU
gpu_devices <- tf$config$list_physical_devices("GPU")
cat("Numero di GPU disponibili:", length(gpu_devices), "\n")
if (length(gpu_devices) > 0) {
  cat("Dettagli GPU:\n")
  print(gpu_devices)
} else {
  cat("Nessuna GPU rilevata.\n")
}

# Carica il dataset MNIST (per esempio)
mnist <- dataset_mnist()
x_train <- mnist$train$x
y_train <- mnist$train$y
x_test  <- mnist$test$x
y_test  <- mnist$test$y

# Preprocessa i dati
x_train <- array_reshape(x_train, c(nrow(x_train), 784)) / 255
x_test  <- array_reshape(x_test, c(nrow(x_test), 784)) / 255
y_train <- to_categorical(y_train, num_classes = 10)
y_test  <- to_categorical(y_test, num_classes = 10)

# Definisce un modello di rete neurale semplice
model <- keras_model_sequential(input_shape = c(784)) |>
  layer_dense(units = 256, activation = 'relu') |>
  layer_dropout(rate = 0.4) |>
  layer_dense(units = 128, activation = 'relu') |>
  layer_dropout(rate = 0.3) |>
  layer_dense(units = 10, activation = 'softmax')

# Compila il modello
model |>
  compile(
    loss = 'categorical_crossentropy',
    optimizer = optimizer_rmsprop(),
    metrics = c('accuracy')
  )

# Addestra il modello (con pochi epoch per mantenere il test veloce)
history <- model |>
  fit(
    x_train, y_train,
    epochs = 5,
    batch_size = 128,
    validation_split = 0.2
  )

# Valuta il modello sul test set
score <- model |>
  evaluate(x_test, y_test, verbose = 0)

# Crea un data.frame con le performance
train_perf <- as_tibble(history[["metrics"]]) |>
  (\(x) mutate(x, epoch = seq_len(nrow(x))))() |>
  rename(
    train_accuracy = accuracy,
    train_loss = loss
  ) |> 
  pivot_longer(
    cols = -epoch,
    names_to = c("stage", "metric"),
    names_pattern = "(.+)_(.+)",
    values_to = "value"
  )
test_perf <- tibble(
    stage = "test",
    accuracy = score[[1]],
    loss = score[[1]]
  ) |>
  pivot_longer(
    cols = -stage,
    names_to = "metric",
    values_to = "value"
  )
performance <- bind_rows(train_perf, test_perf)

# Scrive il risultato in un file CSV nella cartella output
# Crea la cartella output se non esiste
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}
write.csv(performance, file = "output/performance.csv", row.names = FALSE)
cat("Le performance sono state salvate in output/performance.csv\n")

