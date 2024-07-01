locals {
  trimmed_prefix = substr(random_pet.rg_name.id, 0, 8)
}

