# laims-dgx

## Descrizione del Progetto

Il progetto **laims-dgx** fornisce strumenti per l'addestramento di modelli di deep learning su un server DGX (8×H100), accessibile esclusivamente tramite SLURM in modalità batch con Singularity. L'obiettivo è facilitare l'esecuzione di workflow di deep learning su hardware ad alte prestazioni in dotazione all'Ateneo di Padova (UniPD) e, nello specifico, all'Unità di Biostatisica, Epidemiologia e Sanità Pubblica (UBEP) del Diparitmento di Scienze Cardio-Toraco-Vascolari e Sanità Pubblica (DSCTV), in particolare tramite il suo Laboratorio di Intelligenza Artificiale per le Scienze Mediche (LAIMS), in modo riproducibile e gestito tramite container. In particolare, laims-dgx utilizza container Docker (convertiti in immagini Singularity per il DGX) e script di supporto per semplificare l'uso delle risorse GPU tramite job batch.

## Istruzioni per l'installazione e uso

### Requisiti di sistema
Il sistema è stato testato per le fasi di sviluppo/prototipizzazione locale su Linux Ubuntu 24.04 LTS con Docker installato con supporto per GPU NVIDIA (Driver 550.120, CUDA 12.4, cuDNN 8), una GPU NVIDIA Quadro RTX 5000 con 16GB. Lato server HPC, la DGX fornisce fino 8 GPU H100 (in fase di test il supporto multi-DGX, ovvero 9+ H100) e i nodi di calcolo sono accessibili esclusivamente tramite l' invio di job batch SLURM a cui inviare container Singularity.

### Dipendenze software
Assicurarsi di aver installato Docker e i driver NVIDIA necessari, e compatibili con il proprio hardware, per l'esecuzione di container con supporto GPU. Il progetto utilizza un'immagine base NVIDIA TensorFlow:tensorflow:25.01-tf2-py3, basata anch'essa su Ubuntu 24.04 LTS, a cui vengono aggiunti R e pacchetti R utili per il Deep Learning (tensorflow e keras3) oltre che quelli per l' analisi di dati (attualmente solo il tidyverse, in espansione a richiesta di altri pacchetti).

### Test/Prototipizzazione locale e deploy su DGX
1. Clonare questo repository sul sistema locale per sviluppo.
2. Scrivere lo script di training in R (run.R).
3. Aggiungere all' ultimo RUN (affianco insieme al `{tidyverse}`) i pacchetti R che sono utili
4. Costruire l'immagine Docker con `make build`, che produce un container contenente l'ambiente R e Python necessari.
5. Eseguire un test locale del training lanciando `make run`.
6. Verificato il corretto funzionamento in locale, ed eventualmente ricominciare dal punto 2 in caso di errori, o modifiche allo script.

7. Verificato il corretto funzionamento in locale (verosimilmente su un sottoinsieme di dati di esempio), taggare e pushare l'immagine su un registry (ad es. Docker Hub) usando `make push` (dopo aver configurato i parametri nel Makefile).

8. Farsi un'idea delle risorse necessarie per l'addestramento e aggiornare i parametri dello script `submit.sh` adeguati per il server DGX. I più importanti sono: `--gres=gpu:1` (numero di GPU richieste, ciascuna ha 80 GB di VRAM), `--cpus-per-task=8`, `--mem=32G` (RAM richiesta su CPU, oltre la quale il job viene spento), `--time=24:00:00` (tempo di esecuzione previsto, dopo il quale il job viene spento).

> NOTA BENE: il server DGX è un ambiente condiviso e le risorse sono importanti per tutti. A tal proposito, il tempo di attesa per l'esecuzione di job dipende dalle risorse richieste, garantendo maggiore priorità a chi richiede le risorse adeguate al proprio lavoro (ovevro, sfrutta quasi tutta la RAM richiesta, senza eccedere; così come dichiara tempi di esecuzione vicini e non eccessivamente sovrabbondanti rispetto ai tempi di effettiva esecuzione).

9. A questo punto, spostarsi sul nodo di login del cluster HPC, e recuperare l'immagine convertendola in formato Singularity in un solo comando tramite `make pull-singularity` (che scarica l'immagine Docker da Docker Hub e la converte in formato Singularity `.sif`, nominandola in automatico con il nome della cartella in cui si trova).

10. Infine, eseguire il job sul DGX sottomettendo lo script SLURM (submit.sh) tramite il comando `make run-singularity`. Questo avvierà l'esecuzione batch del container Singularity sulla DGX; i log della console e degli errori generati saranno disponibili nella directory di lavoro, cosìi come gli output (per esempio come nello script di esempio dentro una cartella `output/`).

> NOTA BENE: per tenere monitorato il lavoro in esecuzione si riceveranno notifiche via email (all' avvio, al termine, o al blocco in caso di errore), e si potrà controllare lo stato del job tramite il comando `squeue -u $USER`. Per vedere l'intera coda del server, si può usare `squeue`, infine per vedere tutto lo storico delle proprie chiamate con gli esiti, si può usare il comando `sacct -u $USER`.

## Struttura del Repository

- **Makefile**: Contiene target predefiniti per costruire e gestire l'immagine container e l'esecuzione degli script.

- **submit.sh**: Questo script Bash è uno script di submission SLURM preconfigurato per eseguire il training sul DGX. Contiene direttive #SBATCH per specificare risorse e parametri del job (come 1 task, 2 CPU, 2 GPU, 1GB RAM, tempo 5 minuti di esecuzione prevista).

- **run.R**: Script R di training di esempio che viene eseguito all'interno del container. Lo script è pensato come esempio per testare che l'ambiente funzioni correttamente (da sostituire o modificare con il proprio codice di training).

- **Dockerfile**: Definisce l'immagine Docker di base per l'ambiente di training. Modificare (o aprire un issue per chiedere di rendere la modifica integrata nel progetto) il `Dockerfile` caricando, oltre a `{tidyverse}` gli altri pacchetti necessari per le fasi di pre-/post`-processing e analisi dei dati. (ricordando comunque che il server è dedicato per l'addestramento di reti neurale e potrebbe essere sprecato per fasi di pre-/post-processing di analisi meno intensive; che si consiglia di eseguire altrove).

> NOTA BENE: Il `Dockerfile` espone `Rscript` come __entrypoint__ , il che significa che il container eseguirà direttamente script R per default!!

# Contatti e Supporto

Per assistenza, suggerimenti o segnalazioni, aprire un issue qui sul progetto.
