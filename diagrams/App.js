// src/App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Home from './pages/Home';
import Shop from './pages/Shop';
import './App.css';

function Navbar() {
  return (
    <nav className="terminal-nav">
      <div className="nav-brand">YVES_OS v1.0</div>
      <div className="nav-links">
        <Link to="/">[HOME]</Link>
        <Link to="/shop">[DIRECTORY: SHOP]</Link>
      </div>
    </nav>
  );
}

function App() {
  return (
    <Router>
      <div className="terminal-container">
        <div className="scanlines"></div>
        <Navbar />
        <main className="terminal-content">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/shop" element={<Shop />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;