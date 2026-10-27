import { normalizeWhitespace } from "../utils/strings.js";
import type { ProductRepository } from "./repository.js";

export interface NewProduct {
  name: string;
  priceCents: number;
  sku: string;
}

export interface Product extends NewProduct {
  id: string;
  createdAt: Date;
}

export async function createProduct(repo: ProductRepository, input: NewProduct): Promise<Product> {
  if (input.priceCents < 0) {
    throw new RangeError("priceCents must be non-negative");
  }

  const product: Product = {
    ...input,
    name: normalizeWhitespace(input.name),
    id: crypto.randomUUID(),
    createdAt: new Date(),
  };

  await repo.insert(product);
  return product;
}
