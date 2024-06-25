import torch
import torchvision
import os

'''
This model is based on the Cats & Dogs classifier from TirendazAcademy on Kaggle:

https://www.kaggle.com/code/tirendazacademy/cats-dogs-classification-with-pytorch?scriptVersionId=127290261&cellId=41

slightly modified in the first layer owing to our preprocessing the training images
to use only a single color channel instead of three.
'''
class ImageClassifier(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.conv_layer_1 = torch.nn.Sequential(
          torch.nn.Conv2d(1, 64, 3, padding=1),
          torch.nn.ReLU(),
          torch.nn.BatchNorm2d(64),
          torch.nn.MaxPool2d(2))
        self.conv_layer_2 = torch.nn.Sequential(
          torch.nn.Conv2d(64, 512, 3, padding=1),
          torch.nn.ReLU(),
          torch.nn.BatchNorm2d(512),
          torch.nn.MaxPool2d(2))
        self.conv_layer_3 = torch.nn.Sequential(
          torch.nn.Conv2d(512, 512, kernel_size=3, padding=1),
          torch.nn.ReLU(),
          torch.nn.BatchNorm2d(512),
          torch.nn.MaxPool2d(2))
        self.classifier = torch.nn.Sequential(
          torch.nn.Flatten(),
          torch.nn.Linear(in_features=2048, out_features=2))
    def forward(self, x: torch.Tensor):
        x = self.conv_layer_1(x)
        x = self.conv_layer_2(x)
        for _ in range(4):
            x = self.conv_layer_3(x)
        x = self.classifier(x)
        return x


if __name__ == "__main__":
    global_rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])

    torch.distributed.init_process_group(backend="nccl")
    torch.cuda.set_device(local_rank)
    train_set = torchvision.datasets.ImageFolder(root="/tmp/train", transform=torchvision.transforms.Compose([torchvision.transforms.Grayscale(), torchvision.transforms.ToTensor()]), target_transform=None)
    model = ImageClassifier()
    model.to(local_rank)
    model = torch.nn.parallel.DistributedDataParallel(model, device_ids=[local_rank])
    optimizer = torch.optim.SGD(model.parameters(), lr=1e-3)
    train_data = torch.utils.data.DataLoader(
        train_set,
        batch_size=32,
        pin_memory=True,
        shuffle=False,
        sampler=torch.utils.data.distributed.DistributedSampler(train_set)
    )

    for epoch in range(50):
        total_loss = 0.0
        num_batches = 0

        batch_size = len(next(iter(train_data))[0])
        train_data.sampler.set_epoch(epoch)
        for source, targets in train_data:
            source = source.to(local_rank)
            targets = targets.to(local_rank)
            optimizer.zero_grad()
            output = model(source)
            loss = torch.nn.functional.cross_entropy(output, targets)

            torch.distributed.all_reduce(loss, op=torch.distributed.ReduceOp.SUM)
            loss /= torch.distributed.get_world_size()
            total_loss += loss.item()
            num_batches += 1

            loss.backward()
            optimizer.step()

        average_loss = total_loss / num_batches
        print(f"[Node{global_rank}] Epoch {epoch} | Batchsize: {batch_size} | Steps: {len(train_data)} | Average Loss: {average_loss:.4f}")

    torch.distributed.destroy_process_group()
    if global_rank == 0:
        torch.save(model.state_dict(), os.path.join(os.environ["DATA_ROOT"], "final.pt"))
