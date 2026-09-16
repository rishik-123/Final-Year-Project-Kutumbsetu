// src/pages/Home.js
import React from 'react';
import { Link } from 'react-router-dom';

export default function Home() {
  return (
    <div className="page-home">
      <pre className="ascii-art">
{`
 __  __     __     __     ______     ______    
/\\ \\_\\ \\   /\\ \\  _ \\ \\   /\\  ___\\   /\\  ___\\   
\\ \\____ \\  \\ \\ \\/ ".\\ \\  \\ \\  __\\   \\ \\___  \\  
 \\/\\_____\\  \\ \\__".~"\\_\\  \\ \\_____\\  \\/\\_____\\ 
  \\/_____/   \\/_/   \\/_/   \\/_____/   \\/_____/ 
                                               
`}
      </pre>
      
      <div className="terminal-text">
        <p>{">"} INITIALIZING YVES MAINFRAME...</p>
        <p>{">"} LOADING APPAREL PROTOCOLS... OK.</p>
        <p>{">"} SYSTEM READY.</p>
        <br/>
        <p>Welcome to YVES. Premium threads for the digital age.</p>
        <br/>
        <Link to="/shop" className="terminal-button">
          C:\YVES{">"} RUN SHOP.EXE <span className="cursor">_</span>
        </Link>
      </div>
    </div>
  );
}