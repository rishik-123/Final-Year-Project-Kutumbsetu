// src/pages/Shop.js
import React, { useState } from 'react';
import { products } from '../data';

export default function Shop() {
  const [cart, setCart] = useState([]);

  const handleAddToCart = (item) => {
    setCart([...cart, item]);
    alert(`> SYSTEM MESSAGE: ${item.name} ADDED TO INVENTORY`);
  };

  return (
    <div className="page-shop">
      <div className="shop-header">
        <h2>DIRECTORY: /USER/APPAREL</h2>
        <div className="cart-status">
          {">"} CART_MEMORY: {cart.length} ITEMS ALLOCATED
        </div>
      </div>

      <div className="product-grid">
        {products.map((product) => (
          <div key={product.id} className={`product-card ${product.stock === 'OUT_OF_STOCK' ? 'disabled' : ''}`}>
            <div className="product-id">FILE: {product.id}</div>
            <h3 className="product-name">{product.name}</h3>
            <div className="product-details">
              <p>TYPE: {product.type}</p>
              <p>DESC: {product.description}</p>
              <p>STATUS: {product.stock}</p>
            </div>
            <div className="product-footer">
              <span className="price">${product.price.toFixed(2)}</span>
              <button 
                onClick={() => handleAddToCart(product)}
                disabled={product.stock === 'OUT_OF_STOCK'}
                className="add-button"
              >
                {product.stock === 'OUT_OF_STOCK' ? '[UNAVAILABLE]' : '[EXECUTE BUY]'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}