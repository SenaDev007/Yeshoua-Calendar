function App() {
  console.log('Composant App rendu avec succès');
  
  return (
    <div className="loading-container">
      <h1 className="loading-title">
        Calendrier de YHWH Elohim
      </h1>
      <p className="loading-text">
        L'application se charge...
      </p>
      <div className="loading-spinner"></div>
    </div>
  );
}

export default App;
