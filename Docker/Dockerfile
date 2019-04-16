FROM swift:5.0-bionic

RUN apt-get update && \
    apt-get install -y python3-pip wget unzip p7zip

RUN pip3 install https://download.pytorch.org/whl/cpu/torch-1.0.1.post2-cp36-cp36m-linux_x86_64.whl && \
    pip3 install torchvision

COPY swiftai.py /usr/local/lib/python3.6/dist-packages/

RUN cd /home && \
    git clone https://github.com/sjaz24/SwiftAI.git && \
    cd SwiftAI && \
    mkdir data && \
    swift build

RUN cd /home/SwiftAI/data && \
    wget https://s3.amazonaws.com/fast-ai-imageclas/mnist_png.tgz && \
    tar -xvzf mnist_png.tgz && \
    rm mnist_png.tgz

RUN mkdir /root/.torch && \
    mkdir /root/.torch/models && \
    wget https://download.pytorch.org/models/resnet34-333f7ec4.pth -P /root/.torch/models/

RUN cd /home/SwiftAI/data && \
    wget https://s3.amazonaws.com/fast-ai-imageclas/cifar10.tgz && \
    tar -xvzf cifar10.tgz && \
    rm cifar10.tgz

RUN mkdir /root/.kaggle && \
    pip3 install kaggle
COPY kaggle.json /root/.kaggle/

RUN cd /home/SwiftAI/data && \
    mkdir dogscats && \
    cd dogscats && \
    kaggle competitions download -c dogs-vs-cats-redux-kernels-edition && \
    unzip train.zip && \
    unzip test.zip && \
    rm train.zip && \
    rm test.zip

RUN cd /home/SwiftAI/data && \
    mkdir planet && \ 
    cd planet && \
    kaggle competitions download -c planet-understanding-the-amazon-from-space -f train_v2.csv && \
    unzip train_v2.csv.zip && \
    kaggle competitions download -c planet-understanding-the-amazon-from-space -f train-jpg.tar.7z && \
    p7zip -d train-jpg.tar.7z && \
    tar -xvf train-jpg.tar && \
    mv train-jpg train && \
    rm train-jpg.tar && \
    mkdir test && \
    cd test && \
    kaggle competitions download -c planet-understanding-the-amazon-from-space -f test-jpg.tar.7z && \
    p7zip -d test-jpg.tar.7z && \
    tar -xvf test-jpg.tar && \
    kaggle competitions download -c planet-understanding-the-amazon-from-space -f test-jpg-additional.tar.7z && \
    p7zip -d test-jpg-additional.tar.7z && \
    tar -xvf test-jpg-additional.tar && \
    rm train_v2.csv.zip && \
    rm test-jpg.tar && \ 
    rm test-jpg-additional.tar

RUN cd /home/SwiftAI/data && \
    mkdir pascal && \
    cd pascal && \
    wget http://host.robots.ox.ac.uk/pascal/VOC/voc2007/VOCtrainval_06-Nov-2007.tar && \
    tar -xvf VOCtrainval_06-Nov-2007.tar && \
    mkdir train && \
    mv VOCdevkit/VOC2007/JPEGImages/*.jpg train && \
    rm VOCtrainval_06-Nov-2007.tar && \
    rm -r VOCdevkit && \
    wget http://host.robots.ox.ac.uk/pascal/VOC/voc2007/VOCtest_06-Nov-2007.tar && \
    tar -xvf VOCtest_06-Nov-2007.tar && \
    mkdir test && \
    mv VOCdevkit/VOC2007/JPEGImages/*.jpg test && \
    rm VOCtest_06-Nov-2007.tar && \
    rm -r VOCdevkit

COPY pascal_*.json /home/SwiftAI/data/pascal/

WORKDIR /home/SwiftAI

