# ---------------------------------------------------------------------------
# Variabili di configurazione:
#
# version:       La versione dell'immagine Docker, utile per il versioning.
# name:          Il nome del progetto, derivato dalla cartella corrente.
# sif_image:     Nome dell'immagine Singularity (SIF) generata, basato sul nome.
# image:         Nome completo dell'immagine Docker (name:version).
# dh_account:    L'account (ad esempio su Docker Hub) usato per taggare/pushare l'immagine.
# submit_file    Nome del file usato per sottomettere i job sulla DGX
# ---------------------------------------------------------------------------
version     ?= v1.1
name        ?= $(notdir $(CURDIR))
sif_image   ?= $(name)_$(version).sif
image       := $(name):$(version)
dh_account  ?= corradolanera
submit_file ?= ./submit.sh

# ---------------------------------------------------------------------------
# Gestione degli argomenti extra:
#
# ARGS: Filtra gli argomenti passati che non corrispondono a target noti.
# script: Se viene passato un argomento extra (per esempio, un nome di script da eseguire)
#         lo usa; altrimenti, usa il valore di default (run.R).
# Questo permette di eseguire script diversi senza modificare il Makefile.
# ---------------------------------------------------------------------------
ARGS   := $(filter-out all update restart stop run run-cpu remove build tag push singularity, $(MAKECMDGOALS))
script := $(if $(ARGS), $(firstword $(ARGS)), run.R)

# ---------------------------------------------------------------------------
# Dichiarazione dei target PHONY:
#
# Serve ad evitare conflitti se esistono file con lo stesso nome dei target.
# ---------------------------------------------------------------------------
.PHONY: all build run run-cpu stop remove tag push pull-singularity run-singularity restart update

# ---------------------------------------------------------------------------
# Target: all
#
# Target di default che esegue "update", ovvero build e push.
#
# Perché: Consente di aggiornare l'ambiente e testarlo con un singolo comando.
# ---------------------------------------------------------------------------
all: build run stop remove

# ---------------------------------------------------------------------------
# Target: build
#
# Costruisce l'immagine Docker usando il Dockerfile presente nella directory.
# L'immagine viene taggata con il nome e la versione specificati.
#
# Perché: Assicura che l'immagine contenga tutte le dipendenze necessarie per il progetto.
# ---------------------------------------------------------------------------
build:
	docker build -t $(image) .

# ---------------------------------------------------------------------------
# Target: run
#
# Esegue il container Docker in modalità interattiva e lo rimuove automaticamente al termine.
# - --gpus all: Garantisce l'accesso alle GPU (se presenti).
# - --name $(name): Da semplicemente il nome al containier
# - -u $(shell id -u):$(shell id -g): Fa in modo che il container venga eseguito con l'utente corrente (che esegue il container) simulando da un lato il comportamento di singularity sulla DGX, dall' altro (visto che Docker altrimenti esegue come root) garantisce che i file scritti sul disco montato siano di proprietà dell' utente che lo monta 
# - -v $(PWD):/proj: Monta la directory corrente (contenente il progetto) in /proj nel container.
# - $(script): Specifica lo script R da eseguire (default: run.R, oppure quello passato come argomento).
#
# Perché: Consente di testare l'immagine e lo script in un ambiente controllato ma con impostazioni analoghe a quelle di esecuzione finale.
# ---------------------------------------------------------------------------
run:
	docker run -it --rm --gpus all --name $(name) -u $(shell id -u):$(shell id -g) -v $(CURDIR):/project $(image) $(script)

run-cpu:
	docker run -it --rm --name $(name) -u $(shell id -u):$(shell id -g) -v $(CURDIR):/project $(image) $(script)
# ---------------------------------------------------------------------------
# Target: stop
#
# Arresta il container in esecuzione (se presente).
# "|| true" serve a non far fallire il target se il container non è attivo.
#
# Perché: Utile per interrompere manualmente l'esecuzione del container.
# ---------------------------------------------------------------------------
stop:
	docker stop $(name) || true

# ---------------------------------------------------------------------------
# Target: remove
#
# Rimuove il container (se presente).
# "|| true" impedisce errori se il container non esiste.
#
# Perché: Serve per pulire l'ambiente eliminando i container non più necessari.
# ---------------------------------------------------------------------------
remove:
	docker rm $(name) || true

# ---------------------------------------------------------------------------
# Target: tag
#
# Crea due tag per l'immagine Docker:
# - Uno con la versione specifica (es. project:v0.5)
# - Uno "latest" per indicare l'ultima versione stabile.
#
# Perché: Facilita il versioning e la distribuzione dell'immagine su repository remoti.
# ---------------------------------------------------------------------------
tag:
	docker tag $(image) $(dh_account)/$(name):$(version)
	docker tag $(image) $(dh_account)/$(name):latest

# ---------------------------------------------------------------------------
# Target: push
#
# Esegue il push dell'immagine taggata sul repository remoto.
# Dipende dal target "tag" per assicurarsi che l'immagine sia correttamente taggata.
#
# Perché: Permette di distribuire l'immagine per l'uso su altri sistemi (es. HPC, produzione).
# ---------------------------------------------------------------------------
push: tag
	docker push -a $(dh_account)/$(name)

# ---------------------------------------------------------------------------
# Target: pull-singularity
#
# Usa Singularity per scaricare (pull) la versione Docker dell'immagine e convertirla in SIF.
# ---------------------------------------------------------------------------
pull-singularity:
	singularity pull docker://$(dh_account)/$(name):$(version)

# ---------------------------------------------------------------------------
# Target: run-singularity
#
# Esegue l'immagine Singularity.
# - Crea la directory "output" se non esiste (per salvare eventuali artefatti).
# - Esegue lo script R specificato usando Rscript.
# - --nv: Abilita il supporto GPU in Singularity.
#
# Perché: Consente di eseguire il container in ambienti dove Singularity è preferito (es. HPC).
# ---------------------------------------------------------------------------
run-singularity:
	mkdir -p output
	sbatch --export=SIF_FILE=/mnt/projects/dctv/dgx/u0043/$(name)/$(sif_image) $(submit_file)

# ---------------------------------------------------------------------------
# Dummy target:
#
# Serve ad assorbire eventuali argomenti extra passati da riga di comando,
# evitando errori se viene specificato un target non definito.
# ---------------------------------------------------------------------------
%:
	@:

