import type { Product } from "./createProduct.js";

export interface ProductRepository {
  insert(product: Product): Promise<void>;
  findBySlug(slug: string): Promise<Product | undefined>;
}
