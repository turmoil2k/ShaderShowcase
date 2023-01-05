Shader "Unlit/DynamicYMask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TopTex ("_TopTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 tangent : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _TopTex;
            float4 _TopTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = TRANSFORM_TEX(v.uv, _TopTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldDir(v.normal);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz),v.tangent.w);
                return o;
            }

            float3 Unity_Contrast_float(float3 In, float Contrast)
            {
                float midpoint = pow(0.5, 2.2);
                return float3((In - midpoint) * Contrast + midpoint);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //float3 worldPos = mul(unity_ObjectToWorld, i.vertex);
                //return float4 (1,1,0,1);
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 topCol = tex2D(_TopTex, i.uv);
                //float3 normalWS = UnityObjectToWorldDir(pow(i.normal.xyz,1));
                float3 contrastNorm = saturate(Unity_Contrast_float(i.normal,4));
                //float3 a = Unity_Contrast_float(i.normal,1);
                //float3 normalWSC = Unity_Contrast_float(saturate(normalWS),1);
                //float3 b = (0,0,0);
                //float3 w = (1,1,1);
                float3 lerpAll = lerp(col,topCol,contrastNorm.yyy);
                //float4 finalWrap = float4(normalWSC.yyy,1) + col;
                return float4(lerpAll,1);



                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //return col;
            }
            ENDCG
        }
    }
}
