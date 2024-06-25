import os
from torchvision import transforms
from PIL import Image
import zipfile

t = transforms.Compose([
    transforms.Resize(size=(128,128)),
    transforms.Grayscale(),
    transforms.RandomHorizontalFlip(p=0.5),
    transforms.RandomVerticalFlip(p=0.5)
])

batch_task_index = int(os.environ["BATCH_TASK_INDEX"])
data_root = os.environ["DATA_ROOT"]
extract_root = "/tmp"
normalized_data_root = f"/tmp/bin{batch_task_index}"
os.system(f"mkdir -p {os.path.join(normalized_data_root, 'train')}")

training_data_archive = os.path.join(data_root, "train.zip")

bin_size = int(os.environ["BIN_SIZE"])
first = batch_task_index * bin_size
with zipfile.ZipFile(training_data_archive, "r") as inzf, zipfile.ZipFile(f"bin{batch_task_index}.zip", "w") as outzf:
    for idx in range(first, first + bin_size):
        for cat_or_dog in [ "cat", "dog" ]:
            filename = f"train/{cat_or_dog}.{idx}.jpg"
            inzf.extract(filename, path=extract_root)
            in_image = Image.open(os.path.join(extract_root, filename))
            out_image = t(in_image)
            tmp_path = os.path.join(normalized_data_root, filename)
            out_image.save(tmp_path)
            outzf.write(tmp_path, arcname=f"train/{cat_or_dog}/{idx}.jpg")

os.system(f"cp bin{batch_task_index}.zip {data_root}")
