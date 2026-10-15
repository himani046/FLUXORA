import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import './styles.css';

class AppErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }
  static getDerivedStateFromError(error) {
    return { error };
  }
  componentDidCatch(error, info) {
    console.error('FLUXORA render error:', error, info.componentStack);
  }
  render() {
    if (this.state.error) {
      return <main style={{minHeight:'100vh',background:'#101312',color:'#e8ece9',fontFamily:'system-ui,sans-serif',padding:'48px 24px',display:'grid',placeItems:'center'}}>
        <section style={{maxWidth:620,width:'100%',border:'1px solid #583c3c',background:'#171b19',borderRadius:12,padding:28}}>
          <p style={{color:'#ef8d8d',fontSize:12,letterSpacing:2}}>FLUXORA · RECOVERY MODE</p>
          <h1 style={{fontSize:24,margin:'10px 0'}}>The dashboard hit a rendering error.</h1>
          <p style={{color:'#a6b0a8',lineHeight:1.6}}>The app has been kept from becoming a blank screen. Refresh once; if it continues, copy the technical detail below and share it so the underlying error can be fixed.</p>
          <pre style={{whiteSpace:'pre-wrap',overflowWrap:'anywhere',background:'#0f1210',borderRadius:8,padding:14,color:'#f0b0b0',fontSize:12}}>{String(this.state.error?.message || this.state.error)}</pre>
          <button onClick={() => window.location.reload()} style={{background:'#c3f0cf',color:'#15241a',border:0,borderRadius:6,padding:'11px 16px',fontWeight:700,cursor:'pointer'}}>Reload dashboard</button>
        </section>
      </main>;
    }
    return this.props.children;
  }
}

const root = document.getElementById('root');
if (root) {
  createRoot(root).render(<React.StrictMode><AppErrorBoundary><App /></AppErrorBoundary></React.StrictMode>);
} else {
  document.body.innerHTML = '<main style="padding:32px;font:16px system-ui;background:#101312;color:#e8ece9;min-height:100vh">FLUXORA could not find its root element. Check apps/web/index.html.</main>';
}
