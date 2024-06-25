"""A script to fine tune the llama2-7b model on the American Stories dataset."""

import argparse
import os
import datasets
import peft
import torch
import transformers

parser = argparse.ArgumentParser()
parser.add_argument("--input", help="Directory to find the original model in")
parser.add_argument("--output", help="Directory to place fine tuned model")
args = parser.parse_args()

model_path = os.path.join(args.input, "llama2-7b")
finetuned_model_path = os.path.join(args.output, "llama2-7b-american-stories")

tokenizer = transformers.AutoTokenizer.from_pretrained(
    model_path, local_files_only=True
)
model = transformers.AutoModelForCausalLM.from_pretrained(
    model_path,
    torch_dtype=torch.float16,
    device_map="auto",
    trust_remote_code=True,
)

dataset = datasets.load_dataset(
    "dell-research-harvard/AmericanStories",
    "subset_years",
    year_list=["1809", "1810", "1811", "1812", "1813", "1814", "1815"],
)
dataset = datasets.concatenate_datasets(dataset.values())

if tokenizer.pad_token is None:
  tokenizer.add_special_tokens({"pad_token": "[PAD]"})
  model.resize_token_embeddings(len(tokenizer))

data = dataset.map(
    lambda x: tokenizer(x["article"], padding="max_length", truncation=True)
)

lora_config = peft.LoraConfig(
    r=16, lora_alpha=32, lora_dropout=0.05, bias="none", task_type="CAUSAL_LM"
)

model = peft.prepare_model_for_kbit_training(model)

# add LoRA adaptor
model = peft.get_peft_model(model, lora_config)
model.print_trainable_parameters()

training_args = transformers.TrainingArguments(
    per_device_train_batch_size=1,
    gradient_accumulation_steps=4,
    warmup_steps=2,
    num_train_epochs=1,
    learning_rate=2e-4,
    fp16=True,
    logging_steps=1,
    output_dir=finetuned_model_path,
    optim="paged_adamw_32bit",
)

trainer = transformers.Trainer(
    model=model,
    train_dataset=data,
    args=training_args,
    data_collator=transformers.DataCollatorForLanguageModeling(
        tokenizer, mlm=False
    ),
)
model.config.use_cache = (
    False  # silence the warnings. Please re-enable for inference!
)

trainer.train()

# Merge the fine tuned layer with the base model and save it
# you can remove the line below if you only want to store the LoRA layer
model = model.merge_and_unload()

model.save_pretrained(finetuned_model_path)
tokenizer.save_pretrained(finetuned_model_path)
# Beginning of story in the dataset
prompt = """
In the late action between Generals


Brown and Riall, it appears our men fought
with a courage and perseverance, that would
"""
input_ids = tokenizer(prompt, return_tensors="pt").input_ids
gen_tokens = model.generate(
    input_ids,
    do_sample=True,
    temperature=0.8,
    max_length=100,
)
print(tokenizer.batch_decode(gen_tokens)[0])
