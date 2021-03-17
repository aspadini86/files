# Para dizer a imagem-base que queremos, utilizamos a palavra FROM mais o nome da imagem.
FROM ubuntu
# Copiando o conteudo do diretorio corrente para dentro do docker
#COPY . /var/www
# Qual vai ser o meu Work Directory
#WORKDIR /var/www
# Instalando o node
RUN apt-get update
RUN apt-get install -y nginx 
CMD ["echo","Image Created"]
# O ENTRYPOINT, que executará o comando que quisermos assim que o container for carregado:
#ENTRYPOINT npm start
# Abrindo a porta 3000 para fora do docker
#EXPOSE 3000


## Copilando imagem
## docker build -f Dockerfile -t aspadini/node . 

## docker images 

## docker run aspaidni/node 
