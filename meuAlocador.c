#include "meuAlocador.h"

Bloco* inicioLista = NULL;

void* fimHeapAtual = NULL;

void iniciaAlocador() {
    topoInicialHeap = (void*) syscall(SYS_brk, 0);
    fimHeapAtual = topoInicialHeap;
    if (topoInicialHeap == (void*) -1) {
        perror("Erro ao obter topo inicial da heap");
    }
}

void finalizaAlocador() {
    if (topoInicialHeap == NULL) {
        fprintf(stderr, "Erro: topoInicialHeap não foi inicializado.\n");
        return;
    }

    void* resultado = (void*) syscall(SYS_brk, topoInicialHeap);
    if (resultado != topoInicialHeap) {
        perror("Erro ao restaurar topo da heap");
    }
}


void* alocaMem(int num_bytes) {
    if (num_bytes <= 0) return NULL;

    Bloco* atual = inicioLista;

    // 1. Procurar bloco livre com tamanho suficiente
    while (atual) {
        if (atual->livre && atual->tamanho >= num_bytes) {
            atual->livre = 0;
            return (void*)(atual + 1);
        }
        atual = atual->prox;
    }

    // 2. Não encontrou, alocar novo bloco no fim da heap
    void* novoTopo = fimHeapAtual + TAMANHO_CABECALHO + num_bytes;
    if ((void*) syscall(SYS_brk, novoTopo) == (void*) -1) {
        perror("Erro ao expandir heap");
        return NULL;
    }

    Bloco* novo = (Bloco*) fimHeapAtual;
    novo->tamanho = num_bytes;
    novo->livre = 0;
    novo->prox = NULL;

    fimHeapAtual = novoTopo;

    if (inicioLista == NULL) {
        inicioLista = novo;
    } else {
        atual = inicioLista;
        while (atual->prox) {
            atual = atual->prox;
        }
        atual->prox = novo;
    }

    return (void*)(novo + 1);
}

int liberaMem(void* bloco) {
    if (!bloco) return -1;

    Bloco* header = ((Bloco*)bloco) - 1;
    if (header->livre) return -1;

    header->livre = 1;
    return 0;
}
void imprimeMapa() {
    Bloco* atual = inicioLista;
    while (atual) {
        // Parte gerencial (estrutura Bloco)
        for (size_t i = 0; i < sizeof(Bloco); i++) {
            putchar('#');
        }

        // Parte de dados (livre ou ocupada)
        char c = atual->livre ? '-' : '+';
        for (int i = 0; i < atual->tamanho; i++) {
            putchar(c);
        }

        atual = atual->prox;
    }

    putchar('\n');
}

